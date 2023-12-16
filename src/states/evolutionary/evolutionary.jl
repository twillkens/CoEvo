module Evolutionary

using ...Abstract.States: State
using ...Abstract.Ecosystems: EcosystemCreator
using ...States.Global: GlobalState
using ...Species: AbstractSpecies

struct EcosystemState 
    ecosystem_creator::E1
    ecosystem::E2
end

struct OutcomeState
    evaluations::Vector{E2}
    results::Vector{R}
    individual_outcomes::Dict{Int, Dict{Int, Float64}}
end

struct EvolutionaryState{
    E1 <: EcosystemCreator, E2 <: Ecosystem, E2 <: Evaluation, R <: Result
} <: State 
    global_state::GlobalState
    ecosystem_state::EcosystemState
    outcome_state::OutcomeState
end

struct EvolutionaryStateCreator{R <: Real}
    id::String
    trial::Int
    n_generations::Int
    seed::R
    garbage_collection_interval
end


end
