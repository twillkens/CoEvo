module Global

export GlobalState, load_global_state, load_most_recent_global_state

using Random: AbstractRNG
using ...Counters.Basic: BasicCounter
using ...Counters: Counter
using ...Abstract.States: State, get_generation, get_rng, get_individual_id_counter, get_gene_id_counter
using ...Abstract.States: get_rng_state_after_creation
using ...NewConfigurations.GlobalConfigurations: GlobalConfiguration, make_random_number_generator
using HDF5: File, read

Base.@kwdef struct GlobalState <: State
    generation::Int
    rng::AbstractRNG
    rng_state_after_creation::String
    individual_id_counter::Counter
    gene_id_counter::Counter
    reproduction_time::Float64
    simulation_time::Float64
    evaluation_time::Float64
end

function GlobalState(config::GlobalConfiguration)
    state = GlobalState(
        generation = 0, 
        rng = make_random_number_generator(config), 
        rng_state_after_creation = "",
        individual_id_counter = BasicCounter(),
        gene_id_counter = BasicCounter(),
        reproduction_time = 0.0, 
        simulation_time = 0.0, 
        evaluation_time = 0.0
    )
    return state
end

function GlobalState(
    reproduction_time::Float64, simulation_time::Float64, evaluation_time::Float64, state::State
)
    state = GlobalState(
        get_generation(state),
        get_rng(state),
        get_rng_state_after_creation(state),
        get_individual_id_counter(state),
        get_gene_id_counter(state),
        simulation_time,
        reproduction_time,
        evaluation_time,
    )
    return state
end
using StableRNGs: StableRNG

function load_global_state(file::File, generation::Int)
    base_path = "generations/$generation/global_state"
    rng_state_after_creation = read(file["$base_path/rng_state_after_creation"])
    gene_id_counter_state = read(file["$base_path/gene_id_counter_state"])
    individual_id_counter_state = read(file["$base_path/individual_id_counter_state"])
    reproduction_time = read(file["$base_path/reproduction_time"])
    simulation_time = read(file["$base_path/simulation_time"])
    evaluation_time = read(file["$base_path/evaluation_time"])
    globals = GlobalState(
        generation, 
        StableRNG(state = parse(UInt128, rng_state_after_creation)),
        rng_state_after_creation,
        BasicCounter(individual_id_counter_state),
        BasicCounter(gene_id_counter_state),
        reproduction_time,
        simulation_time,
        evaluation_time,
    )
    return globals
end

function load_most_recent_global_state(file::File)
    generations = [parse(Int, key) for key in keys(file["generations"])]
    gen = maximum(generations)
    state = load_global_state(file, gen)
    return state
end


end