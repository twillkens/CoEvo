module Evaluations

export ScalarFitnessEvalCfg, DiscoEvalCfg

using ...CoEvo: Evaluation, EvaluationConfiguration

"""
    ScalarFitnessEvalCfg <: EvaluationConfiguration

A configuration for scalar fitness evaluations. This serves as a placeholder for potential configuration parameters.
"""
Base.@kwdef struct ScalarFitnessEvalCfg <: EvaluationConfiguration end

"""
    ScalarFitnessEval

Represents an evaluation based on scalar fitness.

# Fields
- `id::Int`: The identifier for the evaluation.
- `fitness::Float64`: The fitness score associated with this evaluation.
"""
struct ScalarFitnessEval <: Evaluation
    id::Int
    fitness::Float64
end

"""
    DiscoEvalCfg <: EvaluationConfiguration

A configuration for the Disco evaluation. This serves as a placeholder for potential configuration parameters.
"""
Base.@kwdef struct DiscoEvalCfg <: EvaluationConfiguration end

"""
    DiscoEval

Represents a Disco evaluation which includes fitness, rank, crowding distance, 
dominance count, list of dominated evaluations, and derived tests.

# Fields
- `fitness::Float64`: The fitness score.
- `rank::Int`: Rank of the individual based on non-dominated sorting.
- `crowding::Float64`: Crowding distance in the objective space.
- `dom_count::Int`: Number of solutions that dominate this individual.
- `dom_list::Vector{Int}`: List of solutions dominated by this individual.
- `derived_tests::Vector{Float64}`: Derived test results.
"""
Base.@kwdef mutable struct DiscoEval <: Evaluation
    fitness::Float64
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
    derived_tests::Vector{Float64} = Float64[]
end

end