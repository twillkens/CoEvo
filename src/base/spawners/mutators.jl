export IdentityMutator, BitflipMutator

struct IdentityMutator <: Mutator end

function(r::IdentityMutator)(::Variator, ::Int, children::Vector{<:Individual})
    children
end

struct BitflipMutator <: Mutator
    mutrate::Float64
end