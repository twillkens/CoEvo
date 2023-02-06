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

function(m::BitflipMutator)(indiv::VectorIndiv)
    newgenes = ScalarGene{Bool}[]
    for gene in indiv.genes
        if rand(m.rng) < m.mutrate
            newgene = ScalarGene(gid!(m.sc), indiv.iid, indiv.gen, !gene.val)
            push!(newgenes, newgene)
        else
            push!(newgenes, gene)
        end
    end
    VectorIndiv(indiv.spkey, indiv.iid, indiv.gen, newgenes, indiv.pids, indiv.outcomes)
end