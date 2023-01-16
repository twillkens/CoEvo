export DefaultBitstringConfig, RandomBitstringConfig, BitstringReproducer
export BitstringGeno

struct BitstringGeno <: Genotype
    key::String
    genes::Vector{Bool}
    parents::Set{String}
end

Base.@kwdef struct DefaultBitstringConfig <: GenoConfig
    width::Int
    default_val::Bool
end

function(cfg::DefaultBitstringConfig)(key::String)
    v = fill(cfg.default_val, cfg.width)
    BitstringGeno(key, v, Set{String}())
end

Base.@kwdef struct RandomBitstringConfig <: GenoConfig
    width::Int
    rng::AbstractRNG
end

function(cfg::RandomBitstringConfig)(key::String)
    v = rand(cfg.rng, Bool, cfg.width)
    BitstringGeno(key, v, Set{String}())
end

Base.@kwdef struct BitstringReproducer <: Reproducer
    rng::AbstractRNG
    mutrate::Float64
end

function(r::BitstringReproducer)(key::String, parent::BitstringGeno)
    new_genes = [rand(r.rng) < r.mutrate ?
        rand(r.rng, Bool) : bit for bit in parent.genes]
    BitstringGeno(key, new_genes, Set([parent.key]))
end

# Base.@kwdef struct SlowBitstringReproducer <: Reproducer
#     rng::AbstractRNG
#     mutrate::Float64
# end
