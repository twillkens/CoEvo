module Truncation

using Random: AbstractRNG

using ...Replacers.Abstract: Replacer
using ....Species.Abstract: AbstractSpecies
using ....Evaluators.Abstract: Evaluation
using ....Evaluators.Interfaces: get_ranked_ids

# Returns the best npop individuals from both the population and children
Base.@kwdef struct TruncationReplacer <: Replacer
    type::Symbol = :plus
end


function replace(
    replacer::TruncationReplacer,
    ::AbstractRNG,
    species::AbstractSpecies,
    evaluation::Evaluation
)
    if length(species.children) == 0
        candidates = species.pop
    elseif replacer.type == :plus
        candidates = merge(species.children, species.pop)
    elseif replacer.type == :comma
        candidates = species.children
    else
        throw(ErrorException("Invalid TruncationReplacer type: $(replacer.type)"))
    end
    ranked_ids = get_ranked_ids(evaluation, collect(keys(candidates)))
    new_pop = Dict(
        id => indiv for (id, indiv) in candidates if id in ranked_ids[1:length(species.pop)]
    )
    return new_pop
end

end