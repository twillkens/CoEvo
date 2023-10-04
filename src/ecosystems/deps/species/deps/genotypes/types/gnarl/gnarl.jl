module GnarlNetworks

export Genes, Genotypes, GnarlNetworkGenotype, GnarlNetworkGenotypeCreator
export GnarlNetworkNodeGene, GnarlNetworkConnectionGene, GnarlMethods 

include("genes.jl")
using .Genes: Genes, GnarlNetworkNodeGene, GnarlNetworkConnectionGene

include("genotypes.jl")
using .Genotypes: GnarlNetworkGenotype, GnarlNetworkGenotypeCreator

include("methods.jl")
using .GnarlMethods: GnarlMethods

end