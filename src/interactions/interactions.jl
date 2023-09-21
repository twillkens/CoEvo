module Interactions

export DomainCfg
export JobCfg
export InteractionResult

include("matchmakers/matchmakers.jl")
include("observations/observations.jl")

using ..CoEvo: Job, JobConfiguration, PhenotypeConfiguration
using ..CoEvo: Ecosystem, Observation, get_pheno_dict, interact
using .Observations: NullObs


struct InteractionRecipe
    domain_id::Int
    indiv_ids::Vector{Int}
end

struct InteractionResult{O <: Observation}
    domain_id::Int
    indiv_ids::Vector{Int}
    outcome_set::Vector{Float64}
    observation::O
end

 InteractionResult(domain_id::Int, indiv_ids::Vector{Int}, outcome_set::Vector{Float64}) =
    InteractionResult(domain_id, indiv_ids, outcome_set, NullObs())


include("domains/domains.jl")
using .Domains: DomainConfiguration, DomainCfg


struct JobCfg{D <: DomainConfiguration} <: JobConfiguration
    domain_cfgs::Vector{D} 
    n_workers::Int
end

function JobCfg(domain_cfgs::Vector{<: DomainConfiguration})
    return JobCfg(domain_cfgs, 1)
end


function make_interaction_recipes(domain_id::Int, cfg::DomainCfg, eco::Ecosystem)
    if length(cfg.entities) != 2
        throw(ArgumentError("Only two-entity interactions are supported for now."))
    end
    species1 = eco.species[cfg.pheno_ids[1]]
    species2 = eco.species[cfg.pheno_ids[2]]
    interaction_ids = cfg.matchmaker(species1, species2)
    interaction_recipes = [
        InteractionRecipe(domain_id, [id1, id2]) for (id1, id2) in interaction_ids
    ]
    return interaction_recipes
end


struct InteractionJob{D <: DomainConfiguration, T} <: Job
    domain_cfgs::Vector{D}
    pheno_dict::Dict{Int, T}
    recipes::Vector{InteractionRecipe}
end

function perform(job::InteractionJob)
    interaction_results = InteractionResult[]
    for recipe in job.recipes
        domain = job.domains[recipe.domain_id]
        phenos = [job.pheno_dict[indiv_id] for indiv_id in recipe.indiv_ids]
        result = interact(domain.problem, domain.obs_cfg, recipe.indiv_ids..., phenos...)
        push!(interaction_results, result)
    end
    return interaction_results
end


function(cfg::JobCfg)(eco::Ecosystem)
    recipes = vcat(
        [
            make_interaction_recipes(domain_id, domain_cfg, eco) 
            for (domain_id, domain_cfg) in enumerate(cfg.domain_cfgs)
        ]...
    )
    recipe_partitions = divvy(recipes, cfg.n_workers)
    pheno_dict = get_pheno_dict(eco)
    jobs = [
        InteractionJob(cfg.domain_cfgs, pheno_dict, recipe_partition)
        for recipe_partition in recipe_partitions
    ]
    if length(jobs) == 1
        interaction_results = perform(jobs[1])
    else
        futures = [remotecall(perform, i, job) for (i, job) in enumerate(jobs)]
        interaction_results = [fetch(f) for f in futures]
    end
    return vcat(interaction_results...)
end

end