module Vectors

export BasicVectorPhenotype

import ..Phenotypes: create_phenotype, act!, reset!

using ...Genotypes.Vectors: BasicVectorGenotype
using ..Phenotypes: Phenotype, PhenotypeCreator

abstract type VectorPhenotype <: Phenotype end 

Base.@kwdef struct BasicVectorPhenotype{T <: Real} <: VectorPhenotype
    id::Int
    values::Vector{T}
end

function BasicVectorPhenotype(values::Vector{T}) where T
    BasicVectorPhenotype(0, values)
end

# Extract the vector of genes from a `BasicVectorGenotype` given a certain phenotype configuration.
function create_phenotype(::PhenotypeCreator, genotype::BasicVectorGenotype, id::Int)
    BasicVectorPhenotype(id, genotype.genes)
end

function act!(phenotype::BasicVectorPhenotype, ::Any)
    phenotype.values
end
 
reset!(phenotype::BasicVectorPhenotype) = nothing

end