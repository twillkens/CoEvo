export VectorIndiv, VectorGene, VectorIndiv, VectorVariator

struct VectorGene{T <: Real} <: Gene
    gen::Int
    origin::String
    val::T
end

struct VectorGeno{T}
    key::String
    genes::Vector{T}
end

struct VectorIndiv{G <: VectorGene, V <: Variation, O <: Outcome} <: Individual
    key::String
    gen::Int
    genes::Vector{G}
    parents::Set{VectorIndiv}
    outcomes::Dict{String, O}
end

function genotype(indiv::VectorIndiv)
    genes = [g.val for g in indiv.genes]
    VectorGeno(indiv.key, genes)
end

Base.@kwdef struct VectorVariator{R <: Recombiner, M <: Mutator} <: GenoConfig
    rng::AbstractRNG
    width::Int
    dtype::Type{<:Real}
    recombiner::R
    mutators::Vector{M}
end

function(v::VectorVariator)(key::String, vec::Vector{<:Real})
    genes = [VectorGene(1, key, val) for val in vec]
    VectorIndiv(key, 1, genes, [GenesisVariation()], Dict{String, Outcome}())
end

function(c::VectorVariator)(key::String, val::Real)
    genes = [VectorGene(1, key, val) for val in fill(c.dtype(val), c.width)]
    VectorIndiv(key, 1, genes, [GenesisVariation()], Dict{String, Outcome}())
end

function(c::VectorVariator)(key::String)
    genes = [VectorGene(1, key, val) for val in rand(c.rng, c.dtype, c.width)]
    VectorIndiv(key, 1, genes, [GenesisVariation()], Dict{String, Outcome}())
end
