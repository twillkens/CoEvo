export IdentityRecombiner, NPointCrossoverRecombiner

struct IdentityRecombiner <: Recombiner end

function(r::IdentityRecombiner)(::Variator, gen::Int, iids::Vector{Int}, parents::Vector{<:Individual})
    [clone(iid, gen, p,) for (iid, p) in zip(iids, parents)]
end

struct NPointCrossoverRecombiner <: Recombiner
    n_points::Int
    rate::Float64
end