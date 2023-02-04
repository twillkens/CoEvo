export FitnessLogger
export BasicGeneLogger
export StatFeatures

Base.@kwdef struct StatFeatures
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

struct FitnessLogger <: Logger
    key::String
end

struct BasicGeneLogger <: Logger
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
# 
# function(l::BasicGeneLogger)(gen_group::JLD2.Group, pop::Population, ::Set{<:Outcome})
#     pop_group = make_group!(gen_group, pop.key) 
#     [l(pop_group, geno) for geno in pop.genos]
# end
# 
# function(l::FitnessLogger)(pop_group::JLD2.Group, geno::Genotype, scorevec::Vector{Float64})
#     geno_group = make_group!(pop_group, geno.key)
#     geno_group["fitness_stats"] = StatFeatures(scorevec)
# end
# 
# function(l::FitnessLogger)(gen_group::JLD2.Group, pop::Population, outcomes::Set{<:Outcome})
#     pop_group = make_group!(gen_group, pop.key) 
#     scorevec_dict = Dict{String, Vector{Float64}}(outcomes)
#     [l(pop_group, geno, scorevec_dict[geno.key]) for geno in pop.genos]
# end
# 
# function(l::Logger)(pops_group::JLD2.Group, pop::Population, outcomes::Set{<:Outcome})
#     pop_group = make_group!(pops_group, pop.key) 
#     [l(pop_group, geno, outcomes) for geno in pop.genos]
# end
# 
# function(l::Logger)(gen_group::JLD2.Group, pops::Set{<:Population}, outcomes::Set{<:Outcome})
#     pops_group = make_group!(gen_group, "pops")
#     popdict = Dict{String, Population}(pops)
#     pop = popdict[l.key]
#     l(pops_group, pop, outcomes)
# end
# 