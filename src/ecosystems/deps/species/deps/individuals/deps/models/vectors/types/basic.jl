
export BasicVectorGenotype, BasicVectorGenotypeCreator

using Random: rand, AbstractRNG
using JLD2: Group

using .....Ecosystems.Utilities.Counters: Counter
using ....Individuals.Abstract: Archiver, Mutator, PhenotypeCreator
using ..Vectors.Abstract: VectorGenotype, VectorGenotypeCreator
using ..Vectors.Abstract: VectorPhenotype, VectorPhenotypeCreator

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

Base.@kwdef struct BasicVectorPhenotype{T <: Real} <: VectorPhenotype
    values::Vector{T}
end

# Extract the vector of genes from a `BasicVectorGenotype` given a certain phenotype configuration.
function create_phenotype(::PhenotypeCreator, geno::BasicVectorGenotype)
    BasicVectorPhenotype(geno.genes)
end

# Serialization utility to save a `BasicVectorGenotype` into a structured archive (utilizing JLD2).
function save_genotype!(::Archiver, geno_group::Group, geno::BasicVectorGenotype)
    geno_group["genes"] = geno.genes
end

# Implement mutation for `BasicVectorGenotype` by introducing random noise to the genes.
function mutate(
    ::Mutator,
    rng::AbstractRNG, ::Counter, geno::BasicVectorGenotype{R}
) where {R <: Real}
    noise = 0.1 .* randn(rng, R, length(geno.genes))
    genes = geno.genes + noise
    geno = BasicVectorGenotype(genes)
    return geno
end
