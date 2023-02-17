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

struct SpeciesLogger <: Logger
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

# function(l::BasicGeneLogger)(pop_group::JLD2.Group, geno::Genotype)
#     geno_group = make_group!(pop_group, geno.key)
#     geno_group["genes"] = geno.genes
#     geno_group["gene_stats"] = StatFeatures(geno.genes)
# end

# function(l::BasicGeneLogger)(gen_group::JLD2.Group, pop::Population, ::Set{<:Outcome})
#     pop_group = make_group!(gen_group, pop.key) 
#     [l(pop_group, geno) for geno in pop.genos]
# end

# function(l::FitnessLogger)(pop_group::JLD2.Group, geno::Genotype, scorevec::Vector{Float64})
#     geno_group = make_group!(pop_group, geno.key)
#     geno_group["fitness_stats"] = StatFeatures(scorevec)
# end

# function(l::FitnessLogger)(gen_group::JLD2.Group, sp::Species{<:Veteran}, ::Set{<:Outcome})
#     sp_group = make_group!(gen_group, sp.spid) 
#     [l(pop_group, geno, scorevec_dict[geno.key]) for geno in pop.genos]
# end

# function(l::Logger)(allsp_group::JLD2.Group, sp::Species{<:Veteran}, outcomes::Set{<:Outcome})
#     sp_group = make_group!(allsp_group, sp.key) 
#     [l(sp_group, geno, outcomes) for geno in pop.genos]
# end

# function(l::Logger)(gen_group::JLD2.Group, allsp::Set{Species{<:Veteran}}, outcomes::Set{<:Outcome})
#     allsp_group = make_group!(gen_group, "species")
#     [l(allsp_group, sp, outcomes) for sp in allsp]
# end

# function(l::SpeciesLogger)(gen_group::JLD2.Group, allsp::Dict{Symbol, <:Species}, ::Vector{<:Outcome})
#     allsp_group = make_group!(gen_group, "species")
#     for sp in values(allsp)
#         sp_group = make_group!(allsp_group, string(sp.spid))
#         for (_, child) in sp.children
#             child_group = make_group!(sp_group, string(child.iid))
#             child_group["vals"] = getvals(child.indiv)
#             child_group["gids"] = getgids(child.indiv)
#             child_group["pids"] = collect(child.indiv.pids)
#         end
#     end
# end


function(l::SpeciesLogger)(sp_group::JLD2.Group, child::FSMIndiv)
    p32 = x -> parse(UInt32, x)
    child_group = make_group!(sp_group, string(child.iid))
    child_group["start"] = child.start
    child_group["ones"] = [p32(x) for x in child.ones]
    child_group["zeros"] = [p32(x) for x in child.zeros]
    child_group["links"] = [(p32(origin), bool, p32(dest)) 
        for ((origin, bool), dest) in child.links]
    #child_group["links"] = child.links
    child_group["pids"] = collect(child.pids)
end

function(l::SpeciesLogger)(gen_group::JLD2.Group, allsp::Dict{Symbol, <:Species}, ::Vector{<:Outcome})
    allsp_group = make_group!(gen_group, "species")
    for sp in values(allsp)
        sp_group = make_group!(allsp_group, string(sp.spid))
        sp_group["popids"] = [ikey.iid for ikey in keys(sp.pop)]
        for (_, child) in sp.children
            l(sp_group, child.indiv)
        end
    end
end


function(l::GeneLogger)(jld2::JLD2.JLDFile, allsp::Set{<:Species}, ::Set{<:Observation})
    gene_group = make_group!(jld2, "genes")
end