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
    ids = [record.id for record in evaluation.disco_records]
    if replacer.n_truncate > 0
        ids = ids[1:replacer.n_truncate]
    end

    new_pop = Dict(
        id => indiv for (id, indiv) in candidates if id in ids
    )

    #fitnesses = [disco_record.fitness for disco_record in evaluation.disco_records]
    #discos = [disco_record.rank for disco_record in evaluation.disco_records]
    #fit_discos = [(round(fitnesses[i], digits=2), discos[i]) for i in 1:replacer.n_truncate]

    #println("discos: ", fit_discos)
    println("----------------------")

    info = [(record.rank, round(record.fitness, digits = 2), round(record.crowding, digits=2)) for record in evaluation.disco_records]
    println("info for $(species.id): ", info)
    #println([record.rank for record in evaluation.disco_records])
    #println([round(record.crowding, digits=2) for record in evaluation.disco_records])
    #println([round(record.fitness, digits=2) for record in evaluation.disco_records])
    println("num clusters: ", length(evaluation.disco_records[1].tests))
    ids = [record.id for record in evaluation.disco_records]
    new_pop = Dict(
        id => indiv for (id, indiv) in candidates if id in ids[1:replacer.n_truncate]
    )
    println("new_pop: ", length(new_pop))
    return new_pop
end

end