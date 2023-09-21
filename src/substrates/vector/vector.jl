"""
    VectorSubstrate

Module providing vector-based genotype configurations and associated utilities.
"""
module VectorSubstrate

export VectorGeno, VectorGenoCfg, RandVectorGenoCfg

using Random
using JLD2
using ...CoEvo.Utilities: Counter
using ...CoEvo: Genotype, GenotypeConfiguration, PhenotypeConfiguration, Archivist

"""
    VectorGeno{T <: Real} <: Genotype

A configuration for a `VectorGeno` genotype that uses a default vector of real numbers.

# Fields
- `default_vector::Vector{T}`: Default vector values for the genotype (default is [0.0]).
"""
struct VectorGeno{T <: Real} <: Genotype
    vals::Vector{T}
end

# Basic utility functions for VectorGeno.

Base.length(indiv::VectorGeno) = length(indiv.vals)
Base.:(==)(indiv1::VectorGeno, indiv2::VectorGeno) = indiv1.vals == indiv2.vals
Base.hash(indiv::VectorGeno, h::UInt) = hash(indiv.vals, h)

"""
    VectorGenoCfg{T <: Real} <: GenotypeConfiguration

A configuration for a `VectorGeno` genotype that uses a default vector of real numbers.

# Fields
- `default_vector::Vector{T}`: Default vector values for the genotype (default is [0.0]).
"""
Base.@kwdef struct VectorGenoCfg{T <: Real} <: GenotypeConfiguration
    default_vector::Vector{T} = [0.0]
end

(cfg::VectorGenoCfg)() = VectorGeno(cfg.default_vector)

# Function to generate a `VectorGeno` from the `VectorGenoCfg`.
function(cfg::VectorGenoCfg)(::AbstractRNG, ::Counter)
    VectorGeno(cfg.default_vector)
end

"""
    RandVectorGenoCfg <: GenotypeConfiguration

Configuration to define a random vector genotype.

# Fields
- `dtype::Type{<:Real}`: Type of the numbers in the vector.
- `width::Int`: Width (or length) of the vector.
"""
Base.@kwdef struct RandVectorGenoCfg <: GenotypeConfiguration
    dtype::Type{<:Real}
    width::Int
end

# Function to generate a `VectorGeno` containing random values based on the `RandVectorGenoCfg`.
function(cfg::RandVectorGenoCfg)(rng::AbstractRNG, ::Counter)
    vals = rand(rng, cfg.dtype, cfg.width)
    VectorGeno(vals)
end

# Function to load a `VectorGeno` from an archive (using JLD2).
function(cfg::VectorGenoCfg)(geno_group::JLD2.Group)
    VectorGeno(geno_group["vals"])
end

# Function to store a `VectorGeno` into an archive (using JLD2).
function(a::Archivist)(geno_group::JLD2.Group, geno::VectorGeno,)
    geno_group["vals"] = geno.vals
end

# Return the vector of values from a `VectorGeno` genotype for a given phenotype configuration.
function(cfg::PhenotypeConfiguration)(geno::VectorGeno)
    geno.vals
end

end
