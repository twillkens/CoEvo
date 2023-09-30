
"""
    Abstract Module

Provides foundational abstract functionalities for selector types and 
implements the default behavior for unimplemented selector types.
"""
module Abstract

export Selector, Individual, Evaluation, AbstractRNG

using ......Ecosystems.Species.Evaluators.Criteria.Abstract: Criterion
using .....Ecosystems.Species.Individuals.Abstract: Individual
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation
using Random: AbstractRNG

abstract type Selector end

end # end of Abstract module