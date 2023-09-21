module VectorSubstrate

export VectorGeno, VectorGenoCfg, RandVectorGenoCfg

using Random
using JLD2
using ...CoEvo.Utilities: Counter
using ...CoEvo: Genotype, GenotypeConfiguration, PhenotypeConfiguration, Archivist

"""
    struct VectorGenoCfg{T <: Real} <: GenotypeConfiguration

A simple genotype that stores a vector of values.

# Fields
    vals::Vector{T}
"""
struct VectorGeno{T <: Real} <: Genotype
    vals::Vector{T}
end


# Comparison and hashing functions for VectorGeno

Base.length(indiv::VectorGeno) = length(indiv.vals)
Base.:(==)(indiv1::VectorGeno, indiv2::VectorGeno) = indiv1.vals == indiv2.vals
Base.hash(indiv::VectorGeno, h::UInt) = hash(indiv.vals, h)

# A real-valued vector genotype.
Base.@kwdef struct VectorGenoCfg{T <: Real} <: GenotypeConfiguration
    default_vector::Vector{T} = [0.0]
end

(cfg::VectorGenoCfg)() = VectorGeno(cfg.default_vector)

# Generate a constant vector genotype from the given vector in the configuration.
function(cfg::VectorGenoCfg)(::AbstractRNG, ::Counter)
    VectorGeno(cfg.default_vector)
end

# Define a random vector genotype.
Base.@kwdef struct RandVectorGenoCfg <: GenotypeConfiguration
    dtype::Type{<:Real}
    width::Int
end

# Generate a random vector genotype.
function(cfg::RandVectorGenoCfg)(rng::AbstractRNG, ::Counter)
    vals = rand(rng, cfg.dtype, cfg.width)
    VectorGeno(vals)
end

# Load a VectorGeno from the archive.
function(cfg::VectorGenoCfg)(geno_group::JLD2.Group)
    VectorGeno(geno_group["vals"])
end

# Store a VectorGeno in the archive.
function(a::Archivist)(geno_group::JLD2.Group, geno::VectorGeno,)
    geno_group["vals"] = geno.vals
end

# Return the vector of values from a genotype.
function(cfg::PhenotypeConfiguration)(geno::VectorGeno)
    geno.vals
end

end