module Identity

using ......Ecosystems.Utilities.Counters: Counter, next!

using Random: AbstractRNG
using ...Abstract: Recombiner
using ....Species.Individuals: Individual

import ...Recombiners.Interfaces: recombine

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