export IdentityRecombiner, NPointCrossoverRecombiner
export CloneRecombiner

Base.@kwdef struct IdentityRecombiner <: Recombiner end

function(r::IdentityRecombiner)(::AbstractRNG, ::SpawnCounter, parents::Vector{<:Veteran})
    parents
end

Base.@kwdef struct CloneRecombiner <: Recombiner
end

function(r::CloneRecombiner)(::AbstractRNG, sc::SpawnCounter, parents::Vector{<:Veteran})
    r(sc, parents, [parent.tag for parent in parents])
end

function(r::CloneRecombiner)(::AbstractRNG, sc::SpawnCounter, parents::Vector{<:Veteran}, tags::Vector{Int})
    [clone(iid, p, tag) for (iid, p, tag) in zip(iids!(sc, length(parents)), parents, tags)]
end

struct NPointCrossoverRecombiner <: Recombiner
    n_points::Int
    rate::Float64
end