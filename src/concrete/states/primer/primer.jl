module Primer

export PrimerState

using StableRNGs
import ....Interfaces: create_ecosystem
using ....Abstract
using ....Interfaces

Base.@kwdef struct PrimerState{
    C <: Configuration, R <: Reproducer, S <: Simulator, E <: Evaluator
} <: State
    id::Int
    configuration::C
    generation::Int
    rng::AbstractRNG
    reproducer::R
    simulator::S
    evaluator::E
end

function PrimerState(config::Configuration, generation::Int, rng::AbstractRNG)
    reproducer = create_reproducer(config)
    simulator = create_simulator(config)
    evaluator = create_evaluator(config)
    primer_state = PrimerState(
        id = config.id, 
        configuration = config, 
        generation = generation,
        rng = rng, 
        reproducer = reproducer,
        simulator = simulator,
        evaluator = evaluator
    )
    return primer_state
end

PrimerState(config::Configuration) = PrimerState(config, 1, StableRNG(config.seed))

end