module Identity

export IdentityRecombiner

import ....Interfaces: recombine

using ....Abstract

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