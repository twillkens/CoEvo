module Interfaces

export create_evaluation

using Random: AbstractRNG
using DataStructures: SortedDict

using ..Evaluators.Abstract: Evaluator 
using ...Species.Abstract: AbstractSpecies

# TODO: Add observations to the interface.

function create_evaluation(
    evaluator::Evaluator,
    random_number_generator::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, SortedDict{Int, Float64}},
    #observations::Vector{<:Observation}
)
    throw(ErrorException(
        "`create_evaluation` not implemented for $evaluator and $species."))
end

end