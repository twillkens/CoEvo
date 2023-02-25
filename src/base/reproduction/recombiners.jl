export IdentityRecombiner, NPointCrossoverRecombiner
export CloneRecombiner

Base.@kwdef struct IdentityRecombiner <: Recombiner end

function(r::IdentityRecombiner)(::AbstractRNG, ::SpawnCounter, parents::Vector{<:Veteran})
    parents
end

Base.@kwdef struct CloneRecombiner <: Recombiner
end

function(r::CloneRecombiner)(::AbstractRNG, sc::SpawnCounter, parents::Vector{<:Veteran})
    [clone(iid, p) for (iid, p) in zip(iids!(sc, length(parents)), parents)]
end

struct NPointCrossoverRecombiner <: Recombiner
    n_points::Int
    rate::Float64
end