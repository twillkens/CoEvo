export IdentityReplacer

using Random: AbstractRNG
using DataStructures: OrderedDict
using ....Species.Individuals.Abstract: Individual
using ....Species.Evaluators.Abstract: Evaluator
using ...Replacers.Abstract: Replacer, Individual, Evaluator

import ...Replacers.Abstract: replace

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
    pop_evals::OrderedDict{<:Individual, <:Evaluation},
    children_evals::OrderedDict{<:Individual, <:Evaluation}
)
    if length(pop_evals) > 0
        return pop_evals
    else
        return children_evals
    end
end