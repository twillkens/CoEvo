abstract type Variator end
abstract type Recombiner end
abstract type Mutator end

struct IdentityRecombiner <: Recombiner end

function(r::IdentityRecombiner)(::Variator, gen::Int, childkeys::Vector{String},
        parents::Dict{String, I}) where {I <: Individual}
    [I(childkey, gen, p.genes, Set([p.key]), Dict{String, Outcome}())
    for (childkey, p) in zip(childkeys, parents)]
end

struct NPointCrossoverRecombiner <: Recombiner
    n_points::Int
    rate::Float64
end

function(r::NPointCrossoverRecombiner)(v::VectorVariator, gen::Int,
        childkeys::Vector{String}, parents::Dict{String, I}) where {I <: Individual}
    children = VectorIndiv[]
    for i in 1:2:length(childkeys)
        mother, father = sample(v.rng, collect(values(parents)), 2)
        n_cuts = min(v.width - 1, r.n_points)
        cutpts = sort(sample(v.rng, 1:v.width, n_cuts))
        normal = true
        sisgenes = VectorGene[]
        brogenes = VectorGene[]
        for (i, (mgene, fgene)) in enumerate(zip(mother.genes, father.genes))
            if i ∈ cutpts
                push!(brogenes, fgene)
                push!(sisgenes, mgene)
                normal = false
            else
                push!(brogenes, mgene)
                push!(sisgenes, fgene)
                normal = !normal
            end
        end
        pset = Set([mother.key, father.key])
        bro = VectorIndiv(childkeys[i], gen, brogenes, pset, Set{Outcome}())
        sis = VectorIndiv(childkeys[i + 1], gen, sisgenes, pset, Set{Outcome}())
        append!(children, [bro, sis])
    end
    children
end

struct BitflipMutator <: Mutator
    mutrate::Float64
end

function(m::BitflipMutator)(c::VectorVariator, gen::Int, newkey::String, indiv::VectorIndiv)
    newgenes = VectorGene{c.dtype}[]
    for gene in indiv.genes
        if rand(c.rng) < c.mutrate
            newgene = VectorGene(gen, newkey, rand(c.rng, c.dtype))
            push!(newgenes, newgene)
        else
            push!(newgenes, gene)
        end
    end
    variations = copy(indiv.variations)
    push!(variations, MutationVariation(indiv.key))
    VectorIndiv(newkey, newgenes, variations, Dict{String, Outcome}())
end

function bitflip_mutation(c::VectorVariator, gen::Int,
        childkeys::Vector{String}, indivs::Vector{<:VectorIndiv})
    [bitflip_mutation(c, gen, childkey, indiv)
    for (childkey, indiv) ∈ zip(childkeys, indivs)]
end

function(v::Variator)(gen::Int, childkeys::Vector{String},
        parents::Dict{String, I}) where {I <: Individual}
    children = v.recombiner(v, gen, childkeys, parents)
    for mutator in v.mutators
        children = mutator(v, children)
    end
    Dict([i.key => i for i in indivs])
end
