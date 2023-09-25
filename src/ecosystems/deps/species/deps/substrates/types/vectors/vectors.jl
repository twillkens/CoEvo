"""
    VectorSubstrate

Module offering vector-based genotype configurations along with related utilities.
This module facilitates the definition and management of genotypes that are represented 
as vectors of real numbers.
"""
module Vectors

export BasicVectorGenotype, BasicVectorGenotypeConfiguration

using Random: rand, AbstractRNG
using JLD2: Group
using .....CoEvo.Abstract: Genotype, GenotypeConfiguration, PhenotypeConfiguration
using .....CoEvo.Abstract: Archiver, Mutator, VectorGenotype, VectorGenotypeConfiguration
using .....CoEvo.Utilities.Counters: Counter

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
    BasicVectorGenotypeConfiguration{T <: Real}

A configuration structure designed to set up the `BasicVectorGenotype`.

# Fields
- `default_vector::Vector{T}`: Default values for the genotype's vector. Typically initialized with zeros.
"""
Base.@kwdef struct BasicVectorGenotypeConfiguration{T <: Real} <: VectorGenotypeConfiguration
    default_vector::Vector{T} = [0.0]
end

# Generation of `BasicVectorGenotype` instance based on the given configuration.
function(cfg::BasicVectorGenotypeConfiguration)(::AbstractRNG, ::Counter)
    BasicVectorGenotype(cfg.default_vector)
end

# Extract the vector of genes from a `BasicVectorGenotype` given a certain phenotype configuration.
function(pheno_cfg::PhenotypeConfiguration)(geno::BasicVectorGenotype)
    geno.genes
end

# Serialization utility to save a `BasicVectorGenotype` into a structured archive (utilizing JLD2).
function save_genotype!(::Archiver, geno_group::Group, geno::BasicVectorGenotype)
    geno_group["genes"] = geno.genes
end

# Implement mutation for `BasicVectorGenotype` by introducing random noise to the genes.
function(mutator::Mutator)(
    rng::AbstractRNG, ::Counter, geno::BasicVectorGenotype{R}
) where {R <: Real}
    noise = 0.1 .* randn(rng, R, length(geno.genes))
    genes = geno.genes + noise
    geno = BasicVectorGenotype(genes)
    return geno
end

end
