module VectorSubstrate

export VectorGeno, VectorGenoCfg, RandVectorGenoCfg, VectorGenoArchiver

using Random
using ..Common
using JLD2

# The VectorGeno type is a simple genotype that stores a vector of values,
# where each value is associated with a gene id.
struct VectorGeno{T <: Real} <: Genotype
    vals::Vector{T}
end

# Comparison and hashing functions for VectorGeno
Base.length(indiv::VectorGeno) = length(indiv.vals)
Base.:(==)(indiv1::VectorGeno, indiv2::VectorGeno) = indiv1.vals == indiv2.vals
Base.hash(indiv::VectorGeno, h::UInt) = hash(indiv.vals, h)

# Used for defining a constant vector genotype
Base.@kwdef struct VectorGenoCfg{T <: Real} <: GenoConfig
    vector::Vector{T}
end

function(cfg::VectorGenoCfg)(::AbstractRNG, ::Counter)
    VectorGeno(cfg.vector)
end

# Used for defining a random vector genotype
Base.@kwdef struct RandVectorGenoCfg <: GenoConfig
    dtype::Type{<:Real}
    width::Int
end

function(cfg::RandVectorGenoCfg)(rng::AbstractRNG, sc::SpawnCounter)
    gids = gids!(sc, cfg.width)
    vals = rand(rng, cfg.dtype, cfg.width)
    VectorGeno(gids, vals)
end

# Archiver for VectorGeno
Base.@kwdef struct VectorGenoArchiver <: Archiver end

# Store the gids and vals of a VectorGeno
function(a::VectorGenoArchiver)(geno_group::JLD2.Group, geno::VectorGeno,)
    geno_group["gids"] = geno.gids
    geno_group["vals"] = geno.vals
end

# Load function for VectorGeno from archive
function(cfg::VectorGenoArchiver)(geno_group::JLD2.Group)
    VectorGeno(geno_group["gids"], geno_group["vals"])
end

# Used for defining a phenotype that is a vector of values from a genotype
function(cfg::DefaultPhenoCfg)(geno::VectorGeno)
    geno.vals
end

end