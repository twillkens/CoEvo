export InteractionJobConfiguration
export InteractionRecipe, InteractionJob, perform

using DataStructures: OrderedDict
using ...CoEvo.Abstract: Job, JobConfiguration, DomainConfiguration, Observation, Ecosystem
using .Utilities: divvy
using .Domains: InteractiveDomainConfiguration
using .Domains.Problems: interact


"""
    InteractionRecipe

Defines a template for an interaction. 

# Fields
- `dom_id::Int`: Identifier for the interaction domain.
- `indiv_ids::Vector{Int}`: Identifiers of individuals participating in the interaction.
"""
struct InteractionRecipe
    dom_id::String
    indiv_ids::Vector{Int}
end


"""
    InteractionJob{D <: DomainConfiguration, T} <: Job

Defines a job that orchestrates a set of interactions.

# Fields
- `dom_cfgs::Vector{D}`: Configurations for interaction domains.
- `pheno_dict::Dict{Int, T}`: Dictionary mapping individual IDs to their phenotypes.
- `recipes::Vector{InteractionRecipe}`: Interaction recipes to be executed in this job.
"""
struct InteractionJob{D <: InteractiveDomainConfiguration, T} <: Job
    dom_cfgs::OrderedDict{String, D}
    pheno_dict::Dict{Int, T}
    recipes::Vector{InteractionRecipe}
end

"""
    perform(job::InteractionJob) -> Vector{InteractionResult}

Execute the given `job`, which contains various interaction recipes. Each recipe denotes 
specific entities to interact in a domain. The function processes these interactions and 
returns a list of their results.

# Arguments
- `job::InteractionJob`: The job containing details about the interactions to be performed.

# Returns
- A `Vector` of `InteractionResult` instances, each detailing the outcome of an interaction.
"""
function perform(job::InteractionJob)
    observations = Observation[]
    for recipe in job.recipes
        dom_cfg = job.dom_cfgs[recipe.dom_id]
        phenos = [job.pheno_dict[indiv_id] for indiv_id in recipe.indiv_ids]
        observation = interact(
            dom_cfg.problem, 
            dom_cfg.id, 
            dom_cfg.obs_cfg, 
            recipe.indiv_ids, 
            phenos...
        )
        push!(observations, observation)
    end
    return observations
end

"""
    make_interaction_recipes(dom_id::Int, cfg::DomainCfg, eco::Ecosystem) -> Vector{InteractionRecipe}

Construct interaction recipes for a given domain based on its configuration and an ecosystem.

# Arguments
- `dom_id::Int`: ID of the domain for which the recipes are being generated.
- `cfg::DomainCfg`: The configuration of the domain.
- `eco::Ecosystem`: The ecosystem from which entities are sourced for interactions.

# Returns
- A `Vector` of `InteractionRecipe` instances, detailing pairs of entities to interact.

# Throws
- Throws an `ArgumentError` if the number of entities in the domain configuration isn't 2.
"""
function make_interaction_recipes(
    dom_cfg::InteractiveDomainConfiguration, eco::Ecosystem
)
    if length(dom_cfg.species_ids) != 2
        throw(ArgumentError("Only two-entity interactions are supported for now."))
    end
    species1 = eco.species[dom_cfg.species_ids[1]]
    species2 = eco.species[dom_cfg.species_ids[2]]
    interaction_ids = dom_cfg.matchmaker(species1, species2)
    interaction_recipes = [
        InteractionRecipe(dom_cfg.id, [id1, id2]) for (id1, id2) in interaction_ids
    ]
    return interaction_recipes
end

Base.@kwdef struct InteractionJobConfiguration{
    D <: InteractiveDomainConfiguration
} <: JobConfiguration
    n_workers::Int = 1
    dom_cfgs::OrderedDict{String, D} 
end

# Constructor for JobCfg with a default number of workers.
function InteractionJobConfiguration(
    dom_cfgs::Vector{<:InteractiveDomainConfiguration}
)
    dom_cfgs = OrderedDict(dom_cfg.id => dom_cfg for dom_cfg in dom_cfgs)
    return InteractionJobConfiguration(dom_cfgs, 1)
end


"""
    get_pheno_dict(eco::Eco) -> Dict

Generate a dictionary that maps individual IDs to their respective phenotypes, based on the 
phenotype configuration of each species in the given ecosystem `eco`.

# Arguments:
- `eco`: The ecosystem instance containing the species and their respective individuals.

# Returns:
- A `Dict` where keys are individual IDs and values are the corresponding phenotypes.

# Notes:
- This function fetches phenotypes for both the current population (`pop`) and the offspring (`children`) 
  for each species in the ecosystem.
"""
function get_pheno_dict(eco::Ecosystem)
    Dict(
        indiv_id => species.pheno_cfg(indiv.geno)
        for species in values(eco.species)
        for (indiv_id, indiv) in merge(species.pop, species.children)
    )
end


"""
    (cfg::JobCfg)(eco::Ecosystem) -> Vector{InteractionResult}

Using the given job configuration, construct and execute interaction jobs based on the ecosystem. 
Results from all interactions are aggregated and returned.

# Arguments
- `cfg::JobCfg`: The job configuration detailing domains and number of workers.
- `eco::Ecosystem`: The ecosystem providing entities for interaction.

# Returns
- A `Vector` of `InteractionResult` detailing outcomes of all interactions executed.
"""
function(job_cfg::InteractionJobConfiguration)(eco::Ecosystem)
    recipes = vcat(
        [
            make_interaction_recipes(dom_cfg, eco) 
            for dom_cfg in values(job_cfg.dom_cfgs)
        ]...
    )
    recipe_partitions = divvy(recipes, job_cfg.n_workers)
    pheno_dict = get_pheno_dict(eco)
    jobs = [
        InteractionJob(job_cfg.dom_cfgs, pheno_dict, recipe_partition)
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
