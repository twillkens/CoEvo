export IdentityMutator, BitflipMutator

struct IdentityMutator <: Mutator end

function(r::IdentityMutator)(children::Vector{<:Individual})
    children
end

Base.@kwdef struct BitflipMutator <: Mutator
    rng::AbstractRNG
    sc::SpawnCounter
    mutrate::Float64
end

function(m::BitflipMutator)(indiv::VectorIndiv{ScalarGene{Bool}})
    newgenes = map(gene -> rand(m.rng) < m.mutrate ?
        ScalarGene(gid!(m.sc), !gene.val) : gene, indiv.genes)
    VectorIndiv(indiv.ikey, newgenes, indiv.pids)
end

function(m::Mutator)(indivs::Vector{<:Individual})
    [m(indiv) for indiv in indivs]
end