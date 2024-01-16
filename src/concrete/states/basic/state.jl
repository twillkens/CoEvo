export BasicEvolutionaryState, Timers

using ....Abstract

mutable struct Timers
    reproduction_time::Float64
    simulation_time::Float64
    evaluation_time::Float64
end

@kwdef mutable struct BasicEvolutionaryState{
    C <: Configuration,
    R1 <: Reproducer,
    S <: Simulator,
    E1 <: Evaluator,
    R2 <: Result,
    E2 <: Ecosystem,
    E3 <: Evaluation,
    A <: Archiver
} <: State
    id::Int
    configuration::C
    generation::Int
    rng::AbstractRNG
    rng_state_after_reproduction::String
    reproducer::R1
    simulator::S
    evaluator::E1
    ecosystem::E2
    results::Vector{R2}
    evaluations::Vector{E3}
    archivers::Vector{A}
    checkpoint_interval::Int
    timers::Timers
end

    