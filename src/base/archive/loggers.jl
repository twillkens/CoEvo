export FitnessLogger
export BasicGeneLogger
export StatFeatures
export SpeciesLogger

Base.@kwdef struct StatFeatures
    sum::Float64
    mean::Float64
    variance::Float64
    std::Float64
    minimum::Float64
    lower_quartile::Float64
    median::Float64
    upper_quartile::Float64
    maximum::Float64
end

function StatFeatures(vec::Vector{<:Real})
    min_, lower_, med_, upper_, max_, = nquantile(vec, 4)
    StatFeatures(
        mean = mean(vec),
        variance = var(vec),
        std = std(vec),
        minimum = min_,
        lower_quartile = lower_,
        median = med_,
        upper_quartile = upper_,
        maximum = max_,
    )
end

Base.@kwdef struct SpeciesLogger <: Logger
    interval::Int = 1
end

struct FitnessLogger <: Logger
    key::String
end

struct GeneLogger <: Logger
    key::String
end

function make_group!(parent_group, key)
    key ∉ keys(parent_group) ? JLD2.Group(parent_group, key) : parent_group[key]
end

function(l::SpeciesLogger)(children_group::JLD2.Group, child::FSMIndiv)
    p32 = x -> parse(UInt32, x)
    cgroup = make_group!(children_group, string(child.iid))
    cgroup["start"] = child.start
    cgroup["ones"] = [p32(x) for x in child.ones]
    cgroup["zeros"] = [p32(x) for x in child.zeros]
    cgroup["links"] = [(p32(origin), bool, p32(dest)) 
        for ((origin, bool), dest) in child.links]
    cgroup["pids"] = collect(child.pids)
end

function(l::SpeciesLogger)(children_group::JLD2.Group, child::VectorIndiv)
    cgroup = make_group!(children_group, string(child.iid))
    cgroup["gids"] = [gene.gid for gene in child.genes]
    cgroup["vals"] = [gene.val for gene in child.genes]
    cgroup["pids"] = collect(child.pids)
end

function(l::SpeciesLogger)(
    gen::Int, gensgroup::JLD2.Group, allsp::Dict{Symbol, <:Species}, ::Vector{<:Outcome}
)
    allspgroup = make_group!(gensgroup, "species")
    for sp in values(allsp)
        spgroup = make_group!(allspgroup, string(sp.spid))
        spgroup["popids"] = [ikey.iid for ikey in keys(sp.pop)]
        children_group = make_group!(spgroup, "children")
        vets = gen == 1 ? sp.pop : sp.children
        for (_, vet) in vets
            l(children_group, vet.indiv)
        end
    end
end

function(l::Logger)(gen::UInt16, args...) 
    if gen % l.interval == UInt16(0)
        l(Int(gen), args...)
    end
end


