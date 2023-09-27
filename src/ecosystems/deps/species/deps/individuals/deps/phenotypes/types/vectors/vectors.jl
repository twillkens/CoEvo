module Vectors

export Abstract
export VectorPhenotype, VectorPhenotypeCreator
export BasicVectorPhenotype, BasicVectorPhenotypeCreator
export create_phenotype


module Abstract

export VectorPhenotype, VectorPhenotypeCreator, create_phenotype

abstract type VectorPhenotype end 

abstract type VectorPhenotypeCreator end 

end


using ...Genotypes.Vectors: BasicVectorGenotype
using ..Abstract: Phenotype, PhenotypeCreator
using .Abstract: Abstract, VectorPhenotype, VectorPhenotypeCreator

Base.@kwdef struct BasicVectorPhenotype{T <: Real} <: VectorPhenotype
    values::Vector{T}
end


# Extract the vector of genes from a `BasicVectorGenotype` given a certain phenotype configuration.
function create_phenotype(::PhenotypeCreator, geno::BasicVectorGenotype)
    BasicVectorPhenotype(geno.genes)
end

end