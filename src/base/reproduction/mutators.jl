export IdentityMutator, BitflipMutator

struct IdentityMutator <: Mutator end

function(r::IdentityMutator)(::Int, children::Vector{<:Individual})
    children
end

Base.@kwdef struct BitflipMutator <: Mutator
    rng::AbstractRNG
    sc::SpawnCounter
    mutrate::Float64
end

function(m::BitflipMutator)(indiv::VectorIndiv{ScalarGene{Bool}})
    newgenes = ScalarGene{Bool}[]
    for gene in indiv.genes
        if rand(m.rng) < m.mutrate
            newgene = ScalarGene(gid!(m.sc), !gene.val)
            push!(newgenes, newgene)
        else
            push!(newgenes, gene)
        end
    end
    VectorIndiv(indiv.ikey, newgenes, indiv.pids)
end

function(m::Mutator)(indivs::Set{<:Individual})
    Set(m(indiv) for indiv in indivs)
end


Base.@kwdef struct LingPredMutator <: Mutator
    rng::AbstractRNG
    sc::SpawnCounter
    nmut::Int
end

