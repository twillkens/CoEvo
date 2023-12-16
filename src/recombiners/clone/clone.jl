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
    parents::Vector{<:ModesIndividual};
    reset_tags::Bool = false
) 
    tags = reset_tags ? [i for i in 1:length(parents)] : [parent.tag for parent in parents]
    children = [
        ModesIndividual(
            count!(individual_id_counter), 
            parent.id,
            tag,
            0,
            parent.genotype, 
        ) 
        for (parent, tag) in zip(parents, tags)
    ]
    return children
end

end