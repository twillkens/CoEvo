module GnarlNetworks

import ..Genotypes: create_genotypes, get_size, minimize

using Random: AbstractRNG
using ...Counters: Counter
using ..Genotypes: Genotype, GenotypeCreator, Gene

include("genes.jl")

include("genotype.jl")

include("methods.jl")

end