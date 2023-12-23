module Global

export GlobalState

import ...Abstract.States: get_individual_id_counter_state, get_gene_id_counter_state

using Random: AbstractRNG
using ...Counters.Basic: BasicCounter
using ...Counters: Counter
using ...Abstract.States: State, get_generation, get_rng, get_individual_id_counter, get_gene_id_counter
using ...NewConfigurations.GlobalConfigurations: GlobalConfiguration, make_random_number_generator

Base.@kwdef struct GlobalState <: State
    generation::Int
    rng::AbstractRNG
    individual_id_counter::Counter
    gene_id_counter::Counter
    reproduction_time::Float64
    simulation_time::Float64
    evaluation_time::Float64
end

get_individual_id_counter_state(state::GlobalState) = state.individual_id_counter.state
get_gene_id_counter_state(state::GlobalState) = state.gene_id_counter.state

function GlobalState(config::GlobalConfiguration)
    state = GlobalState(
        generation = 0, 
        rng = make_random_number_generator(config), 
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
        get_generation(state) + 1,
        get_rng(state),
        get_individual_id_counter(state),
        get_gene_id_counter(state),
        simulation_time,
        reproduction_time,
        evaluation_time,
    )
    return state
end


end