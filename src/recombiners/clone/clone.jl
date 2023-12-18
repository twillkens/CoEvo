module Clone

export CloneRecombiner

import ..Recombiners: recombine

using Random: AbstractRNG
using ...Counters: Counter, count!
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ..Recombiners: Recombiner

Base.@kwdef struct CloneRecombiner <: Recombiner end

function recombine(
    ::CloneRecombiner,
    ::AbstractRNG, 
    individual_id_counter::Counter, 
    parents::Vector{<:BasicIndividual}
) 
    children = [
        BasicIndividual(count!(individual_id_counter), parent.genotype, [parent.id]) 
        for parent in parents
    ]
    return children
end

function recombine(
    ::CloneRecombiner,
    ::AbstractRNG, 
    individual_id_counter::Counter, 
    parents::Vector{<:ModesIndividual}
) 
    children = [
        ModesIndividual(
            count!(individual_id_counter), parent.id, parent.tag, 0, parent.genotype,
        ) 
        for parent in parents
    ]
    parent_ids = [parent.id for parent in parents]
    children_ids = [child.id for child in children]
    summaries = [(child_id, parent_id) for child_id in children_ids, parent_id in parent_ids]
    #println("recombiner_results = $summaries")
    return children
end

end