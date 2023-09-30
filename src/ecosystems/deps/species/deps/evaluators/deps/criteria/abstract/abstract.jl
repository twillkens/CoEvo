module Abstract

export Criterion, Evaluation, Individual

using .....Ecosystems.Species.Individuals.Abstract: Individual
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation

abstract type Criterion end

end