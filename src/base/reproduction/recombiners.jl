export IdentityRecombiner, NPointCrossoverRecombiner
export CloneRecombiner

Base.@kwdef struct IdentityRecombiner <: Recombiner end


function(r::IdentityRecombiner)(::Int, parents::Vector{<:Veteran})
    Set(parents)
end

Base.@kwdef struct CloneRecombiner <: Recombiner
    sc::SpawnCounter
end

function(r::CloneRecombiner)(gen::Int, parents::Vector{<:Veteran})
    Set(clone(iid, gen, p)
    for (iid, p) in zip(iids!(r.sc, length(parents)), parents))
end

struct NPointCrossoverRecombiner <: Recombiner
    n_points::Int
    rate::Float64
end