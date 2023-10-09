module Truncation

using Random: AbstractRNG

using ...Replacers.Abstract: Replacer
using ....Species.Abstract: AbstractSpecies
using ....Evaluators.Abstract: Evaluation
using ....Evaluators.Interfaces: get_ranked_ids

import ...Replacers.Interfaces: replace

# Returns the best npop individuals from both the population and children
Base.@kwdef struct TruncationReplacer <: Replacer
    type::Symbol = :comma
    n_truncate::Int = 50
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
    #println("----------------------")

    #info = [(record.rank, round(record.fitness, digits = 2), round(record.crowding, digits=2)) for record in evaluation.disco_records]
    #println("info for $(species.id): ", info)
    #println("num clusters: ", length(evaluation.disco_records[1].tests))
    #println("num records: ", length(evaluation.disco_records))
    ids = [record.id for record in evaluation.disco_records]
    new_pop = Dict(
        id => indiv for (id, indiv) in candidates if id in ids[1:replacer.n_truncate]
    )
    #println("new_pop: ", length(new_pop))
    return new_pop
end

end