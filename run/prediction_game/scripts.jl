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

function make_job_name(n_species::Int, topology::String, reproducer::String)
    interaction_alias = INTERACTION_ALIAS_DICT[topology]
    reproducer_alias = REPRODUCER_ALIAS_DICT[reproducer]
    job_name = string(n_species, interaction_alias, reproducer_alias)
    return job_name
end

function generate_local_script(;
    n_species::Int,
    interaction::String,
    reproducer::String,
    n_generations::Int = 20_000,
    n_trials::Int = 1,
    report::String = "deploy",
    n_nodes_per_output::Int = 1,
    modes_interval::Int = 50,
    n_workers::Int = 1,
    function_set::String = "all",
    mutation::String = "equal_volatile",
    noise_std::String = "moderate",
    adaptive_archive_max_size::Int = 500,
    n_adaptive_archive_samples::Int = 50,
    tag::String = "",
)
    # Use the existing dictionaries to get aliases
    topology = N_SPECIES_ALIAS_DICT[n_species] * "_" * interaction
    job_name = make_job_name(n_species, interaction, reproducer)
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
            --report $report \\
            --reproducer $reproducer \\
            --n_generations $n_generations \\
            --n_nodes_per_output $n_nodes_per_output \\
            --modes_interval $modes_interval \\
            --function_set $function_set \\
            --mutation $mutation \\
            --noise_std $noise_std \\
            --adaptive_archive_max_size $adaptive_archive_max_size \\
            --n_adaptive_archive_samples $n_adaptive_archive_samples \\
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
    reproducer::String,
    user::String = "twillkens",
    n_generations::Int = 20_000,
    n_workers::Int = 1,
    n_trials::Int = 20,
    n_nodes_per_output::Int = 1,
    modes_interval::Int = 50,
    function_set::String = "all",
    mutation::String = "equal_volatile",
    noise_std::String = "high",
    adaptive_archive_max_size::Int = 500,
    n_adaptive_archive_samples::Int = 50,
    tag::String = "",
)
    job_name = make_job_name(n_species, interaction, reproducer)
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
            --report deploy \\
            --reproducer $reproducer \\
            --n_generations $n_generations \\
            --n_nodes_per_output $n_nodes_per_output \\
            --modes_interval $modes_interval \\
            --function_set $function_set \\
            --mutation $mutation \\
            --noise_std $noise_std \\
            --adaptive_archive_max_size $adaptive_archive_max_size \\
            --n_adaptive_archive_samples $n_adaptive_archive_samples \\
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