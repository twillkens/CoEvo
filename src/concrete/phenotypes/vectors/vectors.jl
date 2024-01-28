module Vectors

export BasicVectorPhenotype, CloneVectorPhenotypeCreator

import ....Interfaces: create_phenotype, act!, reset!
using ....Abstract
using ...Genotypes.Vectors: BasicVectorGenotype

abstract type VectorPhenotype <: Phenotype end 

Base.@kwdef mutable struct BasicVectorPhenotype{T <: Real} <: VectorPhenotype
    id::Int
    values::Vector{T}
end

struct CloneVectorPhenotypeCreator <: PhenotypeCreator end

function BasicVectorPhenotype(values::Vector{T}) where T
    BasicVectorPhenotype(0, values)
end

# Extract the vector of genes from a `BasicVectorGenotype` given a certain phenotype configuration.
function create_phenotype(::CloneVectorPhenotypeCreator, id::Int, genotype::BasicVectorGenotype)
    BasicVectorPhenotype(id, genotype.genes)
end

function act!(phenotype::BasicVectorPhenotype, ::Any)
    phenotype.values
end
 
reset!(phenotype::BasicVectorPhenotype) = nothing

end