module Abstract 

export Mutator, AbstractRNG, Genotype

abstract type Mutator end

using Random: AbstractRNG

using ...Genotypes.Abstract: Genotype

end