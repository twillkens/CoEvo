"""
    VectorSubstrate

Module providing vector-based genotype configurations and associated utilities.
"""
module Vectors

export VectorGenotype
export VectorGenotypetypeConfiguration
export RandomVectorGenotypetypeConfiguration

using Random
using ...Utilities: Counter
using .....CoEvo.Abstract: Genotype, GenotypeConfiguration

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
    default_vector::Vector{T} = [0.0]
end

(cfg::VectorGenotypeConfiguration)() = VectorGenotype(cfg.default_vector)

# Function to generate a `VectorGenotype` from the `VectorGenotypeConfiguration`.
function(cfg::VectorGenotypeConfiguration)(::AbstractRNG, ::Counter)
    VectorGenotype(cfg.default_vector)
end

"""
    RandVectorGenotypeConfiguration <: GenotypeConfiguration

Configuration to define a random vector genotype.

# Fields
- `dtype::Type{<:Real}`: Type of the numbers in the vector.
- `width::Int`: Width (or length) of the vector.
"""
Base.@kwdef struct RandomVectorGenotypeConfiguration <: GenotypeConfiguration
    dtype::Type{<:Real}
    width::Int
end

# Function to generate a `VectorGenotype` containing random values based on the `RandVectorGenotypeConfiguration`.
function(cfg::RandomVectorGenotypeConfiguration)(rng::AbstractRNG, ::Counter)
    vals = rand(rng, cfg.dtype, cfg.width)
    VectorGenotype(vals)
end

end
