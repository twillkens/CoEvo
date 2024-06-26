using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Concrete.Genotypes.GnarlNetworks
using CoEvo.Concrete.Counters.Basic
using CoEvo.Concrete.Phenotypes.GnarlNetworks
using Random

using Test

#@testset "Random Fully Connected" begin

genotype_creator = RandomFCGnarlNetworkGenotypeCreator(2, 8, 1)

genotypes = create_genotypes(genotype_creator, Random.GLOBAL_RNG, BasicCounter(1), 1)
println(genotypes)
phenotype = create_phenotype(GnarlNetworkPhenotypeCreator(scaled_tanh, x -> x), 1, genotypes[1])

#end