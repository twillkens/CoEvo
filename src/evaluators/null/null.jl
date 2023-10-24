module Null

export NullEvaluation, NullEvaluator

import ...Evaluators.Interfaces: create_evaluation

using Random: AbstractRNG
using DataStructures: SortedDict
using ...Species.Abstract: AbstractSpecies
using ..Evaluators.Abstract: Evaluation, Evaluator

struct NullEvaluation <: Evaluation end

Base.@kwdef struct NullEvaluator <: Evaluator end

function create_evaluation(
    ::AbstractRNG,
    ::NullEvaluator,
    ::AbstractSpecies,
    ::Dict{Int, SortedDict{Int, Float64}}
) 
    evaluation = NullEvaluation()
    return evaluation
end

end

