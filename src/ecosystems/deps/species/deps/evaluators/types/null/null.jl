module Null

export NullEvaluation, NullEvaluator

using Random: AbstractRNG
using DataStructures: OrderedDict
using ....Species.Abstract: AbstractSpecies
using ....Species.Individuals: Individual
using ...Evaluators.Abstract: Evaluation, Evaluator

import ...Evaluators.Interfaces: create_evaluation, get_ranked_ids

struct NullEvaluation <: Evaluation end


Base.@kwdef struct NullEvaluator <: Evaluator end

function create_evaluation(
    ::NullEvaluator,
    ::AbstractRNG,
    ::AbstractSpecies,
    ::Dict{Int, Dict{Int, Float64}}
) 
    evaluation = NullEvaluation()
    return evaluation
end

function get_ranked_ids(evaluator::NullEvaluation, ::Vector{Int})
    throw(ErrorException("get_ranked_ids not implemented for $evaluator"))
end


end

