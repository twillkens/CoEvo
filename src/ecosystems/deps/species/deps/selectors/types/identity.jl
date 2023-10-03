module Identity

using Random: AbstractRNG

using ...Selectors.Abstract: Selector
using ....Species.Individuals: Individual
using ....Species.Evaluators.Abstract: Evaluation

import ...Interfaces: select

"""
    IdentitySelector

Represents a no-operation selector strategy that simply returns the provided population 
without any selection. This selector can be useful as a default or placeholder, or in scenarios 
where no selection strategy is desired.
"""
struct IdentitySelector <: Selector end

"""
    (selector::IdentitySelector)(rng::AbstractRNG, parent_evals::OrderedDict{<:Individual, <:Evaluation})

Apply the identity selection strategy, returning the provided population as-is.

# Arguments
- `rng::AbstractRNG`: A random number generator. Unused in this context, but provided for consistency with other selectors.
- `parent_evals::OrderedDict{<:Individual, <:Evaluation}`: An ordered dictionary of the population's 
                                                          individuals and their evaluations.

# Returns
- `OrderedDict{<:Individual, <:Evaluation}`: The same ordered dictionary that was provided as input, 
                                            representing the unchanged population.
"""
function select(
    ::IdentitySelector,
    ::AbstractRNG, 
    new_pop::Dict{Int, <:Individual},
    ::Evaluation
)
    parents = collect(values(new_pop))
    return parents
end

end