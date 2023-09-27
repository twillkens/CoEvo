using Random: AbstractRNG
using DataStructures: OrderedDict
using .....CoEvo.Abstract: Individual, Selector, Evaluation

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
function(selector::IdentitySelector)(
    ::AbstractRNG, 
    parent_evals::OrderedDict{<:Individual, <:Evaluation}
)
    return parent_evals
end
