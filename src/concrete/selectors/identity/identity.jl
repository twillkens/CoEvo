module Identity

export IdentitySelector

import ....Interfaces: select

using Random: AbstractRNG
using ....Abstract

struct IdentitySelector <: Selector end

function select(
    ::IdentitySelector,
    ::AbstractRNG, 
    new_population::Vector{<:Individual},
    ::Evaluation
)
    return new_population
end

end