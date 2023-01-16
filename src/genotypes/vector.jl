export VectorGeno, DefaultVectorGenoConfig

struct VectorGeno{T <: Real} <: Genotype
    key::String
    genes::Vector{T}
    parents::Set{String}
end

Base.@kwdef struct DefaultVectorGenoConfig{T <: Real} <: GenoConfig
    width::Int
    default_val::T
end

function(cfg::DefaultVectorGenoConfig)(key::String)
    v = fill(cfg.default_val, cfg.width)
    VectorGeno(key, v, Set{String}())
end
