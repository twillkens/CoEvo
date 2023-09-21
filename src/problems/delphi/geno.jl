export DelphiGenoConfig, DelphiReproducer

Base.@kwdef struct DelphiGenoConfig <: GenoConfig
    width::Int
    rng::AbstractRNG
    min::Float64
    max::Float64
end

function(cfg::DelphiGenoConfig)(key::String)
    v = rand(cfg.rng, Uniform(cfg.min, cfg.max), cfg.width)
    VectorGeno(key, v, Set{String}())
end

Base.@kwdef struct DelphiReproducer <: Reproducer
    rng::AbstractRNG
    mut_dist::Float64
    mut_bias::Float64
end

function(r::DelphiReproducer)(key::String, parent::VectorGeno)
    min_ = -r.mut_dist - r.mut_bias
    max_ = r.mut_dist - r.mut_bias
    noise = rand(rng, Uniform(min_, max_), length(parent.genes))
    new_genes = parent.genes + noise
    VectorGeno(key, new_genes, Set([parent.key]))
end