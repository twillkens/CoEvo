export make_performer, load_globals, get_n_generations, get_n_workers, get_trial
export make_random_number_generator, make_counter, make_individual_id_counter
export make_gene_id_counter, make_state_creator, load_globals

using Random: AbstractRNG
using StableRNGs: StableRNG
using ...Names

struct GlobalConfiguration
    trial::Int
    n_generations::Int
    n_workers::Int
    seed::Int
    rng_state_string::String
    individual_id_counter_state::Int
    gene_id_counter_state::Int
end

function GlobalConfiguration(;
    trial::Int = 1,
    n_generations::Int = 100,
    n_workers::Int = 1,
    seed::Int = 42,
    rng_state_string::String = "",
    individual_id_counter_state::Int = 1,
    gene_id_counter_state::Int = 1,
    kwargs...
)
    configuration = GlobalConfiguration(
        trial,
        n_generations,
        n_workers,
        seed,
        rng_state_string,
        individual_id_counter_state,
        gene_id_counter_state,
    )
    return configuration
end

function archive!(configuration::GlobalConfiguration, file::File)
    base_path = "configuration/globals"
    file["$base_path/trial"] = configuration.trial
    file["$base_path/n_generations"] = configuration.n_generations
    file["$base_path/n_workers"] = configuration.n_workers
    file["$base_path/seed"] = configuration.seed
    file["$base_path/rng_state_string"] = configuration.rng_state_string
    file["$base_path/individual_id_counter_state"] = configuration.individual_id_counter_state
    file["$base_path/gene_id_counter_state"] = configuration.gene_id_counter_state
end

function load_globals(file::File)
    base_path = "configuration/globals"
    substrate = load_type(GlobalConfiguration, file, base_path)
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

get_n_generations(configuration::GlobalConfiguration) = configuration.n_generations

get_n_workers(configuration::GlobalConfiguration) = configuration.n_workers

get_trial(configuration::GlobalConfiguration) = configuration.trial

function make_random_number_generator(configuration::GlobalConfiguration)
    if configuration.rng_state_string == ""
        rng = StableRNG(configuration.seed)
    else
        state = parse(UInt128, configuration.rng_state_string)
        rng = StableRNG(state = state)
    end
    return rng
end

function make_counter(::GlobalConfiguration)
    counter = BasicCounter()
    return counter
end

function make_individual_id_counter(configuration::GlobalConfiguration)
    state = configuration.individual_id_counter_state
    counter = BasicCounter(state)
    return counter
end

function make_gene_id_counter(configuration::GlobalConfiguration)
    state = configuration.gene_id_counter_state
    counter = BasicCounter(state)
    return counter
end

function make_performer(configuration::GlobalConfiguration)
    n_workers = configuration.n_workers
    performer = CachePerformer(n_workers = n_workers)
    return performer
end

function make_state_creator(::GlobalConfiguration)
    state_creator = BasicCoevolutionaryStateCreator()
    return state_creator
end