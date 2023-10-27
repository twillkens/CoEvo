module GnarlNetworks

import ..Genotypes: create_genotypes, get_size, minimize

using Random: AbstractRNG
using ...Counters: Counter
using ..Genotypes: Genotype, GenotypeCreator, Gene

include("genotype.jl")

include("equals.jl")

include("show.jl")

include("methods.jl")

end