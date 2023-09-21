module Evaluations

export ScalarFitnessEvalCfg, DiscoEvalCfg

using ...CoEvo: Evaluation, EvaluationConfiguration

Base.@kwdef struct ScalarFitnessEvalCfg <: EvaluationConfiguration end

struct ScalarFitnessEval <: Evaluation
    id::Int
    fitness::Float64
end

Base.@kwdef struct DiscoEvalCfg <: EvaluationConfiguration end

Base.@kwdef mutable struct DiscoEval <: Evaluation
    fitness::Float64
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
    derived_tests::Vector{Float64} = Float64[]
end

end