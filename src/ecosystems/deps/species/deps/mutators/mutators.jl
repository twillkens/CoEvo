module Mutators

export DefaultMutator

using Random: AbstractRNG
using ....CoEvo.Abstract: Mutator, Individual
using ..Individuals: AsexualIndividual
using ..Utilities: Counter

Base.@kwdef struct DefaultMutator <: Mutator end


function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indiv::I
) where {I <: AsexualIndividual}
    geno = mutator(rng, gene_id_counter, indiv.geno)
    I(indiv.id, geno, indiv.parent_id)
end

function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indivs::Vector{<:Individual}
)
    [mutator(rng, gene_id_counter, indiv) for indiv in indivs]
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