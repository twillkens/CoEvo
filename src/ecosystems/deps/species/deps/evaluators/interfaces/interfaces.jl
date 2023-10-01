module Interfaces

export create_evaluation

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


end