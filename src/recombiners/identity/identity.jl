module Identity

export IdentityRecombiner

import ..Recombiners: recombine

using Random: AbstractRNG
using ...Counters: Counter
using ...Individuals: Individual
using ..Recombiners: Recombiner

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