module Null

export NullEvaluation, NullEvaluator

import ....Interfaces: evaluate

using Random: AbstractRNG
using DataStructures: SortedDict
using ....Abstract: AbstractSpecies, Evaluator, Evaluation

struct NullEvaluation <: Evaluation end

Base.@kwdef struct NullEvaluator <: Evaluator end

function evaluate(
    ::AbstractRNG,
    ::NullEvaluator,
    ::AbstractSpecies,
    ::Dict{Int, SortedDict{Int, Float64}}
) 
    evaluation = NullEvaluation()
    return evaluation
end

end

