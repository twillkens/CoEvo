"""
    VectorSubstrate

Module providing vector-based genotype configurations and associated utilities.
"""
module Vectors

export VectorGenotype
export VectorGenotypetypeConfiguration

using Random: rand, AbstractRNG
using JLD2: Group
using .....CoEvo.Abstract: Genotype, GenotypeConfiguration, PhenotypeConfiguration
using .....CoEvo.Abstract: Archiver, Mutator
using .....CoEvo.Utilities.Counters: Counter

"""
    VectorGenotype{T <: Real} <: Genotype

A configuration for a `VectorGenotype` genotype that uses a default vector of real numbers.

# Fields
- `default_vector::Vector{T}`: Default vector values for the genotype (default is [0.0]).
"""
struct VectorGenotype{T <: Real} <: Genotype
    genes::Vector{T}
end

# Basic utility functions for VectorGenotype.

Base.length(indiv::VectorGenotype) = length(indiv.genes)
Base.:(==)(indiv1::VectorGenotype, indiv2::VectorGenotype) = indiv1.genes == indiv2.genes
Base.hash(indiv::VectorGenotype, h::UInt) = hash(indiv.genes, h)

"""
    VectorGenotypeConfiguration{T <: Real} <: GenotypeConfiguration

A configuration for a `VectorGenotype` genotype that uses a default vector of real numbers.

# Fields
- `default_vector::Vector{T}`: Default vector values for the genotype (default is [0.0]).
"""
Base.@kwdef struct VectorGenotypeConfiguration{T <: Real} <: GenotypeConfiguration
    default_vector::Vector{T} = [0.0]
end

# Function to generate a `VectorGenotype` from the `VectorGenotypeConfiguration`.
function(cfg::VectorGenotypeConfiguration)(::AbstractRNG, ::Counter)
    VectorGenotype(cfg.default_vector)
end


# Return the vector of values from a `VectorGeno` genotype for a given phenotype configuration.
function(pheno_cfg::PhenotypeConfiguration)(geno::VectorGenotype)
    geno.genes
end

# Function to store a `VectorGeno` into an archive (using JLD2).
function save_genotype!(::Archiver, geno_group::Group, geno::VectorGenotype)
    geno_group["genes"] = geno.genes
end

function(mutator::Mutator)(
    rng::AbstractRNG, ::Counter, geno::VectorGenotype{R}
) where {R <: Real}
    noise = 0.1 .* randn(rng, R, length(geno.genes))
    genes = geno.genes + noise
    geno = VectorGenotype(genes)
    return geno
end

end
