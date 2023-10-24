module Clone

export CloneRecombiner

import ...Recombiners.Interfaces: recombine

using Random: AbstractRNG
using ...Counters.Abstract: Counter
using ...Counters.Interfaces: count!
using ...Individuals: Individual
using ..Recombiners.Abstract: Recombiner

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