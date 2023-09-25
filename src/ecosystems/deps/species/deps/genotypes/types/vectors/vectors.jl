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
    vals::Vector{T}
end

# Basic utility functions for VectorGenotype.

Base.length(indiv::VectorGenotype) = length(indiv.vals)
Base.:(==)(indiv1::VectorGenotype, indiv2::VectorGenotype) = indiv1.vals == indiv2.vals
Base.hash(indiv::VectorGenotype, h::UInt) = hash(indiv.vals, h)

"""
    VectorGenotypeConfiguration{T <: Real} <: GenotypeConfiguration

A configuration for a `VectorGenotype` genotype that uses a default vector of real numbers.

# Fields
- `default_vector::Vector{T}`: Default vector values for the genotype (default is [0.0]).
"""
Base.@kwdef struct VectorGenotypeConfiguration{T <: Real} <: GenotypeConfiguration
    default_vector::Union{Vector{T}, Nothing} = nothing
    width::Int = 1
    default_value::Union{T, Nothing} = T(0)
    make_random::Bool = false
end

# Function to generate a `VectorGenotype` from the `VectorGenotypeConfiguration`.
function(cfg::VectorGenotypeConfiguration{T})(rng::AbstractRNG, ::Counter) where {T <: Real}
    if cfg.default_vector !== nothing
        vals = cfg.default_vector
    elseif cfg.make_random
        vals = rand(rng, T, cfg.width)
    else
        vals = fill(cfg.default_value, cfg.width)
    end
    VectorGenotype(vals)
end


# Return the vector of values from a `VectorGeno` genotype for a given phenotype configuration.
function(pheno_cfg::PhenotypeConfiguration)(geno::VectorGenotype)
    geno.vals
end

# Function to store a `VectorGeno` into an archive (using JLD2).
function save_genotype!(::Archiver, geno_group::Group, geno::VectorGenotype)
    geno_group["vals"] = geno.vals
end

function(mutator::Mutator)(
    rng::AbstractRNG, ::Counter, geno::VectorGenotype{R}
) where {R <: Real}
    noise = 0.1 .* randn(rng, R, length(geno.vals))
    vals = geno.vals + noise
    geno = VectorGenotype(vals)
    return geno
end

end
