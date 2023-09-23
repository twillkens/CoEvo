module Evaluations

export ScalarFitnessEvalCfg #, DiscoEvalCfg

using ....CoEvo.Abstract: Evaluation, EvaluationConfiguration

include("types/scalar_fitness.jl")
include("types/disco.jl")


function(eval_cfg::EvaluationConfiguration)(all_outcomes::Dict{<:Individual, Dict{Int, Float64}})
    return Dict(indiv => eval_cfg(indiv.id, outcomes) for (indiv, outcomes) in all_outcomes)
end

# Default behavior is to return a scalar fitness evaluation
function(eval_cfg::EvaluationConfiguration)(id::Int, outcomes::Dict{Int, Float64})
    return ScalarFitnessEvalCfg()(id, outcomes)
end

# Interface to Evaluation requires a function that takes a vector of evaluations and 
# returns a sorted vector of evaluations
function sort_evaluations(evals::Vector{<:Evaluation}, args...)
    throw(ErrorException("sort_evaluations not implemented for $(typeof(evals))"))
end

function sort_evaluations(evals::OrderedDict{<:Individual, <:Evaluation})


end

end