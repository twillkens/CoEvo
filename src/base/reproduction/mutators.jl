export IdentityMutator, BitflipMutator

struct IdentityMutator <: Mutator end

function(r::IdentityMutator)(::AbstractRNG, ::SpawnCounter, children::Vector{<:Individual})
    children
end

Base.@kwdef struct BitflipMutator <: Mutator
    mutrate::Float64
end

function(m::BitflipMutator)(
    rng::AbstractRNG, sc::SpawnCounter, indiv::VectorIndiv{ScalarGene{Bool}}
)
    newgenes = map(gene -> rand(rng) < m.mutrate ?
        ScalarGene(gid!(sc), !gene.val) : gene, indiv.genes)
    VectorIndiv(indiv.ikey, newgenes, indiv.pids)
end

function(m::Mutator)(rng::AbstractRNG, sc::SpawnCounter, indivs::Vector{<:Individual})
    [m(rng, sc, indiv) for indiv in indivs]
end