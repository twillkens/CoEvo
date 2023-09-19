export IdentityRecombiner, NPointCrossoverRecombiner
export CloneRecombiner

Base.@kwdef struct IdentityRecombiner <: Recombiner end

function(r::IdentityRecombiner)(::AbstractRNG, ::SpawnCounter, parents::Vector{<:Individual})
    parents
end

Base.@kwdef struct CloneRecombiner <: Recombiner
end

function(r::CloneRecombiner)(::AbstractRNG, sc::SpawnCounter, parents::Vector{<:Individual},)
    [BasicIndiv(IndivKey(parent.spid, iid!(sc)), parent.geno, parent.iid) for parent in parents]
end

struct NPointCrossoverRecombiner <: Recombiner
    n_points::Int
    rate::Float64
end