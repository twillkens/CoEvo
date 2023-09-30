module Interfaces

export create_evaluation
export sort_indiv_evals

using ..Abstract: Evaluator, Individual

function create_evaluation(
    eval_creator::Evaluator,
    all_indiv_outcomes::Dict{Individual, Dict{Int, Float64}}
)
    throw(ErrorException(
        "`create_evaluation` not implemented for $eval_creator and $all_indiv_outcomes."))
end


end