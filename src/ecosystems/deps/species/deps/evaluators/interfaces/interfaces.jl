module Interfaces

export create_evaluation, get_ranked_ids

using ..Evaluators.Abstract: Evaluator 
using ...Species.Abstract: AbstractSpecies

function create_evaluation(
    evaluator::Evaluator,
    species::AbstractSpecies
    outcomes::Dict{Int, Float64}
)
    throw(ErrorException(
        "`create_evaluation` not implemented for $evaluator and $species."))
end

function get_ranked_ids(evaluator::Evaluator, ids::Vector{Int})
    throw(ErrorException(
        "`get_ranked_ids` not implemented for $evaluator and $species."))
end


end