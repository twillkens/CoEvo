module Abstract

export Reproducer, Individual, Evaluation, AbstractRNG

using Random: AbstractRNG

using ....Ecosystems.Species.Individuals.Abstract: Individual
using ....Ecosystems.Species.Evaluators.Abstract: Evaluation

abstract type Reproducer end

end