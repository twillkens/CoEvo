module Identity

export IdentityRecombiner

import ...Recombiners.Interfaces: recombine

using Random: AbstractRNG
using ...Counters.Abstract: Counter
using ...Individuals: Individual
using ..Recombiners.Abstract: Recombiner


Base.@kwdef struct IdentityRecombiner <: Recombiner end

function recombine(
    ::IdentityRecombiner,
    ::AbstractRNG, 
    ::Counter, 
    parents::Vector{<:Individual}
) 
    return parents
end

end