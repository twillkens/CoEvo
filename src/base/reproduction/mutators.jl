export IdentityMutator, BitflipMutator

struct IdentityMutator <: Mutator end

function(r::IdentityMutator)(::Int, children::Vector{<:Individual})
    children
end

struct BitflipMutator <: Mutator
    rng::AbstractRNG
    sc::SpawnCounter
    mutrate::Float64
end