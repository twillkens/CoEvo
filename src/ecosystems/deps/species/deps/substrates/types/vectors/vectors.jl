"""
    VectorSubstrate

Module providing vector-based genotype configurations and associated utilities.
"""
module Vectors

export BasicVectorGenotype, BasicVectorGenotypeConfiguration

using Random: rand, AbstractRNG
using JLD2: Group
using .....CoEvo.Abstract: Genotype, GenotypeConfiguration, PhenotypeConfiguration
using .....CoEvo.Abstract: Archiver, Mutator, VectorGenotype, VectorGenotypeConfiguration
using .....CoEvo.Utilities.Counters: Counter

"""
    BasicVectorGenotype{T <: Real} <: Genotype

A configuration for a `BasicVectorGenotype` genotype that uses a default vector of real numbers.

# Fields
- `default_vector::Vector{T}`: Default vector values for the genotype (default is [0.0]).
"""
struct BasicVectorGenotype{T <: Real} <: VectorGenotype
    genes::Vector{T}
end

# Basic utility functions for BasicVectorGenotype.

Base.length(indiv::VectorGenotype) = length(indiv.genes)
Base.:(==)(indiv1::VectorGenotype, indiv2::BasicVectorGenotype) = indiv1.genes == indiv2.genes
Base.hash(indiv::VectorGenotype, h::UInt) = hash(indiv.genes, h)

"""
    BasicVectorGenotypeConfiguration{T <: Real} <: GenotypeConfiguration

A configuration for a `BasicVectorGenotype` genotype that uses a default vector of real numbers.

# Fields
- `default_vector::Vector{T}`: Default vector values for the genotype (default is [0.0]).
"""
Base.@kwdef struct BasicVectorGenotypeConfiguration{T <: Real} <: VectorGenotypeConfiguration
    default_vector::Vector{T} = [0.0]
end

# Function to generate a `BasicVectorGenotype` from the `BasicVectorGenotypeConfiguration`.
function(cfg::BasicVectorGenotypeConfiguration)(::AbstractRNG, ::Counter)
    BasicVectorGenotype(cfg.default_vector)
end


# Return the vector of values from a `VectorGeno` genotype for a given phenotype configuration.
function(pheno_cfg::PhenotypeConfiguration)(geno::BasicVectorGenotype)
    geno.genes
end

# Function to store a `VectorGeno` into an archive (using JLD2).
function save_genotype!(::Archiver, geno_group::Group, geno::BasicVectorGenotype)
    geno_group["genes"] = geno.genes
end

function(mutator::Mutator)(
    rng::AbstractRNG, ::Counter, geno::BasicVectorGenotype{R}
) where {R <: Real}
    noise = 0.1 .* randn(rng, R, length(geno.genes))
    genes = geno.genes + noise
    geno = BasicVectorGenotype(genes)
    return geno
end

end
