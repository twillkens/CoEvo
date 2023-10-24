module GnarlNetworks

import ..Genotypes.Interfaces: create_genotypes, get_size, minimize

using Random: AbstractRNG
using ...Counters.Abstract: Counter
using ..Genotypes.Abstract: Genotype, GenotypeCreator
using ..Genotypes.Abstract: Gene

include("genes.jl")

include("genotype.jl")

include("methods.jl")

end