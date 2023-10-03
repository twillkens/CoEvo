module Basic

using Random: AbstractRNG
using ......Ecosystems.Utilities.Counters: Counter
using ..Vectors.Abstract: VectorGenotype, VectorGenotypeCreator

import ...Genotypes.Interfaces: create_genotypes

"""
    BasicVectorGenotype{T <: Real}

A basic representation of a genotype using a vector of real numbers.

# Fields
- `genes::Vector{T}`: A vector representing the genes of the genotype.
"""
struct BasicVectorGenotype{T <: Real} <: VectorGenotype
    genes::Vector{T}
end

# Utility functions for `BasicVectorGenotype`.
Base.length(indiv::VectorGenotype) = length(indiv.genes)
Base.:(==)(indiv1::VectorGenotype, indiv2::BasicVectorGenotype) = indiv1.genes == indiv2.genes
Base.hash(indiv::VectorGenotype, h::UInt) = hash(indiv.genes, h)

"""
    BasicVectorGenotypeCreator{T <: Real}

A configuration structure designed to set up the `BasicVectorGenotype`.

# Fields
- `default_vector::Vector{T}`: Default values for the genotype's vector. Typically initialized with zeros.
"""
Base.@kwdef struct BasicVectorGenotypeCreator{T <: Real} <: VectorGenotypeCreator
    default_vector::Vector{T} = [0.0]
end

# Generation of `BasicVectorGenotype` instance based on the given configuration.
function create_genotype(creator::BasicVectorGenotypeCreator, ::AbstractRNG, ::Counter)
    BasicVectorGenotype(creator.default_vector)
end

function create_genotypes(
    geno_creator::BasicVectorGenotypeCreator, 
    ::AbstractRNG, 
    ::Counter, 
    n_pop::Int
)
    genotypes = [BasicVectorGenotype(geno_creator.default_vector) for _ in 1:n_pop]
    return genotypes
end

Base.@kwdef struct ScalarRangeGenotypeCreator <: VectorGenotypeCreator
    start_value::Float64 = -5.0
    stop_value::Float64 = 4.9
end

function create_genotypes(
    geno_creator::ScalarRangeGenotypeCreator,
    ::AbstractRNG,
    ::Counter,
    n_pop::Int
)
    step_size = (geno_creator.stop_value - geno_creator.start_value) / (n_pop - 1)
    scalars = collect(range(
        geno_creator.start_value, 
        stop=geno_creator.stop_value, 
        step=step_size
    ))
    genotypes = [BasicVectorGenotype([scalar]) for scalar in scalars]
    return genotypes
end


end