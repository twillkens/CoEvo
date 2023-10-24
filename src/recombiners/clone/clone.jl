module Clone

export CloneRecombiner

import ..Recombiners: recombine

using Random: AbstractRNG
using ...Counters: Counter, count!
using ...Individuals: Individual
using ..Recombiners: Recombiner

Base.@kwdef struct CloneRecombiner <: Recombiner end

function recombine(
    ::CloneRecombiner,
    ::AbstractRNG, 
    individual_id_counter::Counter, 
    parents::Vector{<:Individual}
) 
    children = [
        Individual(count!(individual_id_counter), parent.genotype, [parent.id]) 
        for parent in parents
    ]
    return children
end

end