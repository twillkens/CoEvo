using HDF5

using CoEvo
using CoEvo.Names
using CoEvo.Archivers: load

function construct_file_path(
    trial_dir::String, game::String, topology::String, substrate::String, reproducer::String, trial::String)
    joinpath(trial_dir, game, topology, substrate, reproducer, trial) * ".h5"
end

function safely_open_file(file_path::String)
    file = h5open(file_path, "r")
    file
end

function load_genotype(file, individual_id::String, generation_path::String, n_inputs::Int, n_bias::Int, n_outputs::Int, n_nodes_per_output::Int)
    genotype_path = joinpath(generation_path, "$(individual_id)/genotype")
    load(
        BasicArchiver(), 
        FunctionGraphGenotypeCreator(n_inputs, n_bias, n_outputs, n_nodes_per_output),
        file[genotype_path]
    )
end

function load_generation_phenotypes(;
    trial_dir::String = ENV["COEVO_TRIAL_DIR"],
    game::String = "continuous_prediction_game",
    topology::String = "two_competitive",
    substrate::String = "function_graphs",
    reproducer::String = "disco",
    trial::Int = 1,
    generation::Int = 50,
    n_inputs::Int = 2, 
    n_bias::Int = 1, 
    n_outputs::Int = 1, 
    n_nodes_per_output::Int = 1
)
    file_path = construct_file_path(trial_dir, game, topology, substrate, reproducer, string(trial))
    file = safely_open_file(file_path)

    generation_path = "generations/$(generation)/modes/individuals"

    c = LinearizedFunctionGraphPhenotypeCreator()
    phenotypes = []

    for individual_id in keys(file[generation_path])
        genotype = load_genotype(file, individual_id, generation_path, n_inputs, n_bias, n_outputs, n_nodes_per_output)
        pheno = create_phenotype(c, genotype, parse(Int, individual_id))
        push!(phenotypes, pheno)
    end
    close(file)

    phenotypes
end

function get_values(input_type::String)
    if input_type == "random"
        value_1 = rand() * 2 - 1
        value_2 = rand() * 2 - 1
    elseif input_type == "fixed"
        value_1 = -0.0
        value_2 = 0.7
    end
    values = Float32.([value_1, value_2])
    return values
end

function probe_phenotypes(; input_type::String = "random", kwargs...)
    phenotypes = load_generation_phenotypes(; kwargs...)

    trajectories = []
    for phenotype in phenotypes
        trajectory = []
        for _ in 1:8
            values = get_values(input_type)
            action = first(act!(phenotype, values))
            push!(trajectory, Float64(action))
        end
        trajectory = round.(trajectory; digits=2)
        push!(trajectories, trajectory)
    end
    sizes = [phenotype.n_hidden_nodes for phenotype in phenotypes]
    trajectories = [size => trajectory for (size, trajectory) in zip(sizes, trajectories)]
    return trajectories

end

p = ENV["COEVO_TRIAL_DIR"] * "/continuous_prediction_game/two_competitive/function_graphs/disco/1.h5"