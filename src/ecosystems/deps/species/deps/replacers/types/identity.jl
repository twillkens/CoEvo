module Identity

export IdentityReplacer

using Random: AbstractRNG
using ....Species.Replacers.Abstract: Replacer
using ....Species.Abstract: AbstractSpecies
using ....Species.Evaluators.Abstract: Evaluation

import ...Interfaces: replace 

"""
    IdentityReplacer <: Replacer

A replacement strategy that returns the current population (i.e., parents) if it's non-empty. 
If the current population is empty, it returns the children. Essentially, this replacer preserves
the current population by default.
"""
struct IdentityReplacer <: Replacer end

"""
    (r::IdentityReplacer)(::AbstractRNG, pop_evals, children_evals)

Execute the replacement using the `IdentityReplacer` strategy.

# Arguments
- `pop_evals::OrderedDict{<:Individual, <:Evaluation}`: Evaluations of the current population.
- `children_evals::OrderedDict{<:Individual, <:Evaluation}`: Evaluations of the children.

# Returns
- `OrderedDict{<:Individual, <:Evaluation}`: The population after replacement.
"""
function replace(
    ::IdentityReplacer,
    ::AbstractRNG, 
    species::AbstractSpecies,
    ::Evaluation
)
    population = species.pop
    return population
end

end