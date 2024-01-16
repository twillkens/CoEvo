module Primer

export PrimerState

using StableRNGs
import ....Interfaces: create_ecosystem
using ....Abstract

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

end