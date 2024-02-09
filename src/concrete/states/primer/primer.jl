module Primer

export PrimerState

using ....Abstract
using ....Interfaces
using ...Counters.Basic: BasicCounter
using StableRNGs

Base.@kwdef struct PrimerState{
    C1 <: Configuration, 
    C2 <: Counter, 
    E1 <: EcosystemCreator, 
    R <: Reproducer, 
    S <: Simulator, 
    E2 <: Evaluator, 
} <: State
    id::Int
    configuration::C1
    generation::Int
    rng::AbstractRNG
    gene_id_counter::C2
    individual_id_counter::C2
    ecosystem_creator::E1
    reproducers::Vector{R}
    simulator::S
    evaluators::Vector{E2}
end

function PrimerState(config::Configuration, generation::Int, rng::AbstractRNG)
    primer_state = PrimerState(
        id = config.id, 
        configuration = config, 
        generation = generation,
        rng = rng, 
        gene_id_counter = BasicCounter(1),
        individual_id_counter = BasicCounter(1),
        ecosystem_creator = get_ecosystem_creator(config),
        reproducers = create_reproducers(config),
        simulator = create_simulator(config),
        evaluators = create_evaluators(config),
    )
    return primer_state
end

PrimerState(config::Configuration) = PrimerState(config, 1, StableRNG(config.seed))

end