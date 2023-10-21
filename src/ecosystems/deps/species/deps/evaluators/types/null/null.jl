module Null

export NullEvaluation, NullEvaluator

using Random: AbstractRNG
using DataStructures: SortedDict
using ....Species.Abstract: AbstractSpecies
using ....Species.Individuals: Individual
using ...Evaluators.Abstract: Evaluation, Evaluator

import ...Evaluators.Interfaces: create_evaluation

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

