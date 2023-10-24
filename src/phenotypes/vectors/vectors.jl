module Vectors

export BasicVectorPhenotype

import ..Phenotypes.Interfaces: create_phenotype, act!

using ...Genotypes.Vectors: BasicVectorGenotype
using ..Phenotypes.Abstract: PhenotypeCreator

abstract type VectorPhenotype <: Phenotype end 

Base.@kwdef struct BasicVectorPhenotype{T <: Real} <: VectorPhenotype
    values::Vector{T}
end

# Extract the vector of genes from a `BasicVectorGenotype` given a certain phenotype configuration.
function create_phenotype(::PhenotypeCreator, genotype::BasicVectorGenotype)
    BasicVectorPhenotype(genotype.genes)
end

function act!(phenotype::BasicVectorPhenotype, ::Any)
    phenotype.values
end

end