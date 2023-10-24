module Jobs

using Random: AbstractRNG
using ..Species: AbstractSpecies
using ..Phenotypes: PhenotypeCreator

export Basic

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("types/basic.jl")
using .Basic: Basic

end