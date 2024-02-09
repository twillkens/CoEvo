module Primer

export PrimerState

using StableRNGs
using ....Abstract
using ....Interfaces

Base.@kwdef struct PrimerState{
    C1 <: Configuration, C2 <: Counter, E <: Evaluator, R <: Reproducer, S <: Simulator
} <: State
    id::Int
    configuration::C1
    generation::Int
    rng::AbstractRNG
    gene_id_counter::C2
    individual_id_counter::C2
    reproducers::Vector{R}
    simulator::S
    evaluators::Vector{E}
end

function PrimerState(config::Configuration, generation::Int, rng::AbstractRNG)
    primer_state = PrimerState(
        id = config.id, 
        configuration = config, 
        generation = generation,
        rng = rng, 
        ecosystem_creator = get_ecosystem_creator(config),
        reproducers = create_reproducers(config),
        simulator = create_simulator(config),
        evaluators = create_evaluator(config),
    )
    return primer_state
end

PrimerState(config::Configuration) = PrimerState(config, 1, StableRNG(config.seed))

end