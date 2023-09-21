module Mutators

export IdentityMutator

using Random
using ...CoEvo: Individual, Mutator

struct IdentityMutator <: Mutator end

function(r::IdentityMutator)(::AbstractRNG, children::Vector{<:Individual})
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

end