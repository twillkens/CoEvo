module Interfaces

export select

using Random: AbstractRNG
using DataStructures: OrderedDict

using ..Selectors.Abstract: Selector
using ...Species.Abstract: AbstractSpecies
using ...Species.Individuals: Individual
using ...Species.Evaluators.Abstract: Evaluation

"""
    (selector::Selector)(rng::AbstractRNG, new_pop_evals::OrderedDict{<:I, <:E})

Apply a selector strategy on the provided population. This function acts as 
a placeholder for custom selector implementations. If not overridden, 
it throws an error.

# Arguments
- `rng::AbstractRNG`: A random number generator.
- `new_pop_evals::OrderedDict{<:I, <:E}`: An ordered dictionary of the new population's 
                                          individuals and their evaluations.

# Returns
- `OrderedDict{<:Individual, <:Evaluation}`: A new ordered dictionary representing the 
                                            selected population after the selection process.

# Errors
- Throws an `ErrorException` if the selector type is not implemented for the provided 
  individual and evaluation types.
"""
function select(
    selector::Selector,
    ::AbstractRNG, 
    new_pop::Dict{Int, Individual},
    evaluation::Evaluation
)::Vector{Individual}
    throw(ErrorException(
        "Selector $selector not implemented for $evaluation")
    )
end

end