using Base: pipeline, run

const INTERACTION_ALIAS_DICT = Dict(
    "control" => "ctrl",
    "cooperative" => "coop",
    "competitive" => "comp",
    "mixed" => "mix",
)

const REPRODUCER_ALIAS_DICT = Dict(
    "roulette" => "R",
    "disco" => "D",
)

const N_SPECIES_ALIAS_DICT = Dict(
    2 => "two",
    3 => "three",
)

function make_job_name(n_species::Int, n_elites::Int, topology::String, reproducer::String)
    interaction_alias = INTERACTION_ALIAS_DICT[topology]
    reproducer_alias = REPRODUCER_ALIAS_DICT[reproducer]
    elites_tag = n_elites == 0 ? "" : "E"
    job_name = string(n_species, interaction_alias, reproducer_alias) * elites_tag
    return job_name
end

function generate_local_script(;
    n_species::Int,
    interaction::String,
    reproduction::String,
    n_generations::Int = 30_000,
    n_trials::Int = 1,
    n_nodes_per_output::Int = 1,
    archive_interval::Int = 100,
    n_workers::Int = 1,
    function_set::String = "all",
    mutation::String = "shrink_volatile",
    noise_std::String = "high",
    n_population::Int = 50,
    n_children::Int = 50,
    n_elites::Int = 0,
    episode_length::Int = 16,
    tag::String = "",
)
    # Use the existing dictionaries to get aliases
    topology = N_SPECIES_ALIAS_DICT[n_species] * "_" * interaction
    job_name = make_job_name(n_species, n_elites, interaction, reproduction)
    job_name = job_name * "$tag"

    # Generate the bash script content with log redirection
    script = """
    #!/bin/bash

    mkdir -p logs/$job_name

    for i in {1..$n_trials}
    do
       echo "Running trial \$i"
       julia --project=. run/prediction_game/run.jl \\
            --trial \$i \\
            --n_workers $n_workers \\
            --game continuous_prediction_game \\
            --topology $topology \\
            --reproduction $reproduction \\
            --n_generations $n_generations \\
            --n_nodes_per_output $n_nodes_per_output \\
            --archive_interval $archive_interval \\
            --function_set $function_set \\
            --mutation $mutation \\
            --noise_std $noise_std \\
            --n_population $n_population \\
            --n_children $n_children \\
            --n_elites $n_elites \\
            --episode_length $episode_length \\
            > logs/$job_name/\$i.log 2>&1 &
    done
    """

    # Create the filename for the bash script
    filename = "scripts/local/$job_name.sh"

    # Write the script to a file
    open(filename, "w") do file
        write(file, script)
    end
    
    chmod(filename, 0o755)

    # The filename is returned to know where the script is saved
    return filename
end

function generate_slurm_script(;
    n_species::Int, 
    interaction::String, 
    reproduction::String,
    user::String = "twillkens",
    n_generations::Int = 30_000,
    n_workers::Int = 1,
    n_trials::Int = 30,
    n_nodes_per_output::Int = 1,
    archive_interval::Int = 100,
    function_set::String = "all",
    mutation::String = "shrink_volatile",
    noise_std::String = "high",
    n_population::Int = 50,
    n_children::Int = 50,
    n_elites::Int = 0,
    episode_length::Int = 16,
    tag::String = "",
)
    job_name = make_job_name(n_species, n_elites, interaction, reproduction)
    job_name = job_name * "$tag"
    topology = N_SPECIES_ALIAS_DICT[n_species] * "_" * interaction

    # Generate the script
    script = """
    #!/bin/bash

    #SBATCH --job-name=$job_name
    #SBATCH --partition=guest-compute
    #SBATCH --account=guest
    #SBATCH --qos=low
    #SBATCH --array=1-$n_trials%$n_trials
    #SBATCH --ntasks=1
    #SBATCH --cpus-per-task=$n_workers
    #SBATCH --output=logs/$(job_name)/%a.out
    #SBATCH --error=logs/$(job_name)/%a.err

    # Load Julia module or set up the environment
    module purge
    module load gnu7/7.3.0 anaconda/5.2_py2 openmpi3/3.1.0
    source /home/$user/.bashrc
    conda activate "/home/$user/.conda/envs/coevo"

    srun julia --project -e 'push!(LOAD_PATH, "@CoEvo"); using PkgLock; PkgLock.instantiate_precompile()'

    # Run script
    srun julia --project=. run/prediction_game/run.jl \\
            --trial \$SLURM_ARRAY_TASK_ID \\
            --n_workers \$SLURM_CPUS_PER_TASK \\
            --game continuous_prediction_game \\
            --topology $topology \\
            --reproduction $reproduction \\
            --n_generations $n_generations \\
            --n_nodes_per_output $n_nodes_per_output \\
            --archive_interval $archive_interval \\
            --function_set $function_set \\
            --mutation $mutation \\
            --noise_std $noise_std \\
            --n_population $n_population \\
            --n_children $n_children \\
            --n_elites $n_elites \\
            --episode_length $episode_length \\
    """
    filename = "$job_name.slurm"
    filepath = "scripts/slurm/$filename"
    # Write the script to a file
    open(filepath, "w") do file
        write(file, script)
    end
    chmod(filepath, 0o755)
end

function generate_script(;
    type::String = "local",
    kwargs...
)
    if type == "local"
        generate_local_script(;kwargs...)
    elseif type == "slurm"
        generate_slurm_script(;kwargs...)
    else
        throw(ArgumentError("Unknown type: $type"))
    end
end

function generate_scripts()
    for type in ["local", "slurm"]
        for n_species in [2, 3]
            for interaction in ["control", "cooperative", "competitive", "mixed"]
                for reproduction in ["roulette", "disco"]
                    for n_elites in [0, 50]
                        generate_script(
                            type = type,
                            n_species = n_species,
                            interaction = interaction,
                            reproduction = reproduction,
                            n_elites = n_elites,
                        )
                    end
                end
            end
        end
    end
end

using HDF5: File, Group, read, h5open, isfile

function recursively_copy_item(source::File, dest::File, base_path::String)
    if typeof(source[base_path]) == Group
        for sub_item in keys(source[base_path])
            recursively_copy_item(source, dest, "$base_path/$sub_item")
        end
    else
        value = read(source[base_path])
        dest[base_path] = value
    end
end

function copy_data_to_filtered_file(source_file_path, max_generation)
    destination_file_path = replace(source_file_path, r"\.h5$" => "_filtered.h5")

    source_file = h5open(source_file_path, "r")
    destination_file = h5open(destination_file_path, "w")

    try
        recursively_copy_item(source_file, destination_file, "configuration")

        if "generations" in keys(source_file)
            for generation in sort(parse.(Int, collect(keys(source_file["generations"]))), rev = true)
                if generation <= max_generation
                    gen_path = "generations/$(generation)"
                    recursively_copy_item(source_file, destination_file, gen_path)
                end
            end
        end
    finally
        close(source_file)
        close(destination_file)
    end
end

using Base: rename

function rename_files(original_file_path)
    original_backup_file_path = replace(original_file_path, r"\.h5$" => "_orig.h5")
    filtered_file_path = replace(original_file_path, r"\.h5$" => "_filtered.h5")

    if isfile(original_file_path)
        rename(original_file_path, original_backup_file_path)
    end

    if isfile(filtered_file_path)
        rename(filtered_file_path, original_file_path)
    end
end