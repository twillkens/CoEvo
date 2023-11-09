module Vectors

export VectorGenotype, VectorGenotypeCreator
export BasicVectorGenotype, BasicVectorGenotypeCreator, ScalarRangeGenotypeCreator

import ...Genotypes: create_genotypes

using Random: AbstractRNG
using HDF5: Group
using ...Counters: Counter
using ..Genotypes: Genotype, GenotypeCreator

abstract type VectorGenotype <: Genotype end

abstract type VectorGenotypeCreator <: GenotypeCreator end

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
Base.length(individual::VectorGenotype) = length(individual.genes)
Base.:(==)(indiv1::VectorGenotype, indiv2::BasicVectorGenotype) = indiv1.genes == indiv2.genes
Base.hash(individual::VectorGenotype, h::UInt) = hash(individual.genes, h)

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
    genotype_creator::BasicVectorGenotypeCreator, 
    ::AbstractRNG, 
    ::Counter, 
    n_population::Int
)
    genotypes = [BasicVectorGenotype(genotype_creator.default_vector) for _ in 1:n_population]
    return genotypes
end

"""
    ScalarRangeGenotypeCreator

A genotype creator that creates vector genotypes where each genotype has a scalar value from 
a defined range.

# Fields
- `start_value`: The start value of the scalar range.
- `stop_value`: The stop value of the scalar range.

# Notes
The `create_genotypes` function for this creator generates a list of genotypes, each having a scalar 
value taken from a range defined by `start_value` and `stop_value`.
"""

Base.@kwdef struct ScalarRangeGenotypeCreator <: VectorGenotypeCreator
    start_value::Float64 = -2.0
    stop_value::Float64 = 2.0
end

"""
    create_genotypes(genotype_creator::ScalarRangeGenotypeCreator, ...)

Creates a list of vector genotypes, where each genotype has a scalar value from the range 
defined by the `ScalarRangeGenotypeCreator`.
"""
function create_genotypes(
    genotype_creator::ScalarRangeGenotypeCreator,
    ::AbstractRNG,
    ::Counter,
    n_population::Int
)
    step_size = (genotype_creator.stop_value - genotype_creator.start_value) / (n_population - 1)
    scalars = collect(range(
        genotype_creator.start_value, 
        stop=genotype_creator.stop_value, 
        step=step_size
    ))
    genotypes = [BasicVectorGenotype([scalar]) for scalar in scalars]
    return genotypes
end

function load_genotype(::BasicVectorGenotypeCreator, genotype_group::Group)
    genes = genotype_group["genes"]
    return BasicVectorGenotype(genes)
end

end