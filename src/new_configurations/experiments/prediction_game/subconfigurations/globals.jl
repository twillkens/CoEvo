export get_globals, load_globals

using ...NewConfigurations.GlobalConfigurations.Basic: BasicGlobalConfiguration

function get_globals(;
    trial::Int = 1,
    n_generations::Int = 100,
    n_workers::Int = 1,
    seed::Int = 42,
    kwargs...
)
    configuration = BasicGlobalConfiguration(
        trial = trial,
        n_generations = n_generations,
        n_workers = n_workers,
        seed = seed,
    )
    return configuration
end

function load_globals(file::File)
    base_path = "configuration/globals"
    substrate = load_type(BasicGlobalConfiguration, file, base_path)
    return substrate
end

function load_globals(file::File, generation::Int)
    base_path = "generations/$generation/global_state"
    rng_state = read(file["$base_path/rng_state"])
    gene_id_counter_state = read(file["$base_path/gene_id_counter_state"])
    individual_id_counter_state = read(file["$base_path/individual_id_counter_state"])

    globals = load_globals(file)
    globals = GlobalConfiguration(
        globals.trial,
        globals.n_generations,
        globals.n_workers,
        globals.seed,
        rng_state,
        individual_id_counter_state,
        gene_id_counter_state,
    )
    return globals
end