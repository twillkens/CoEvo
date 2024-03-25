module Vectors

export BasicVectorPhenotype, CloneVectorPhenotypeCreator, NumbersGamePhenotypeCreator

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

Base.@kwdef struct NumbersGamePhenotypeCreator <: PhenotypeCreator 
    use_delta::Bool = true
    delta::Float64 = 0.25
end

function round_to_nearest_delta(vector::Vector{Float64}, delta::Float64)
    return [floor(x/delta) * delta for x in vector]
end


function create_phenotype(
    phenotype_creator::NumbersGamePhenotypeCreator, id::Int, genotype::BasicVectorGenotype, 
) 
    if phenotype_creator.use_delta
        values = round_to_nearest_delta(genotype.genes, phenotype_creator.delta)
    else
        values = copy(genotype.genes)
    end
    return BasicVectorPhenotype(id, values)
end

end