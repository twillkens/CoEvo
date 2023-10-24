module Identity

export IdentitySelector

import ..Selectors: select

using Random: AbstractRNG
using ...Individuals: Individual
using ...Evaluators: Evaluation
using ..Selectors: Selector

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