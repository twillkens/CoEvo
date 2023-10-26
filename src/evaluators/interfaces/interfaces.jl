export evaluate

# TODO: Add observations to the interface.

function evaluate(
    evaluator::Evaluator,
    random_number_generator::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, SortedDict{Int, Float64}},
    #observations::Vector{<:Observation}
)
    throw(ErrorException(
        "`evaluate` not implemented for $evaluator and $species."))
end
