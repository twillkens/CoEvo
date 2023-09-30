module Abstract

export Recombiner, Individual, AbstractRNG

using .....Ecosystems.Species.Individuals.Abstract: Individual
using Random: AbstractRNG

abstract type Recombiner end


end