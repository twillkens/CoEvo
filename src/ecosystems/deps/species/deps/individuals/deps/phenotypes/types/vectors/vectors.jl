
module Vectors

export BasicVectorPhenotype, BasicVectorPhenotypeCreator

using ..Abstract: Phenotype, PhenotypeCreator
using ...Individuals.Genotypes.Vectors: BasicVectorGenotype

abstract type VectorPhenotype <: Phenotype end

Base.@kwdef struct BasicVectorPhenotype{T <: Real} <: VectorPhenotype
    values::Vector{T}
end

# Extract the vector of genes from a `BasicVectorGenotype` given a certain phenotype configuration.
function create_phenotype(::PhenotypeCreator, geno::BasicVectorGenotype)
    BasicVectorPhenotype(geno.genes)
end

end