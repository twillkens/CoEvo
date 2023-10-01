
module Abstract

export Replacer, Individual, Evaluation, AbstractRNG

using .....Ecosystems.Species.Evaluators.Criteria.Abstract: Criterion
using .....Ecosystems.Species.Individuals.Abstract: Individual
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation
using Random: AbstractRNG

abstract type Replacer end

end