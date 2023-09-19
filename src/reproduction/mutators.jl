export IdentityMutator, BitflipMutator

struct IdentityMutator <: Mutator end

function(r::IdentityMutator)(::AbstractRNG, ::SpawnCounter, children::Vector{<:Individual})
    children
end

#Base.@kwdef struct BitflipMutator <: Mutator
#    mutrate::Float64
#end
#
#function(m::BitflipMutator)(
#    rng::AbstractRNG, sc::SpawnCounter, indiv::BasicIndiv{VectorGeno{Bool}}
#)
#    newgenes = map(gene -> rand(rng) < m.mutrate ?
#        ScalarGene(gid!(sc), !gene.val) : gene, indiv.genes)
#    BasicIndiv(indiv.ikey, newgenes, indiv.pids)
#end

function(m::Mutator)(rng::AbstractRNG, sc::SpawnCounter, indivs::Vector{<:Individual})
    [BasicIndiv(indiv.ikey, m(rng, sc, indiv.geno), indiv.pid) for indiv in indivs]
end