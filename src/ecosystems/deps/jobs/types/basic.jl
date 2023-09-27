export BasicJob, BasicJobCreator

using DataStructures: OrderedDict
using ...CoEvo.Abstract: Job, JobConfiguration, DomainConfiguration, Observation, Ecosystem
using .Utilities: divvy
using .Domains: InteractiveDomainConfiguration
using .Domains.Problems: interact



"""
    BasicJob{D <: DomainConfiguration, T} <: Job

Defines a job that orchestrates a set of interactions.

# Fields
- `domain_creators::Vector{D}`: Configurations for interaction domains.
- `pheno_dict::Dict{Int, T}`: Dictionary mapping individual IDs to their phenotypes.
- `recipes::Vector{InteractionRecipe}`: Interaction recipes to be executed in this job.
"""
struct BasicJob{D <: DomainCreator, P <: Phenotype} <: Job
    domain_creators::OrderedDict{String, D}
    phenotypes::Dict{Int, P}
    recipes::Vector{InteractionRecipe}
end

"""
    perform(job::BasicJob) -> Vector{InteractionResult}

Execute the given `job`, which contains various interaction recipes. Each recipe denotes 
specific entities to interact in a domain. The function processes these interactions and 
returns a list of their results.

# Arguments
- `job::BasicJob`: The job containing details about the interactions to be performed.

# Returns
- A `Vector` of `InteractionResult` instances, each detailing the outcome of an interaction.
"""
function perform(job::BasicJob)
    domains = Dict(
        scheme.id => create_domain(scheme) 
        for scheme in job.domain_creators
    )
    observers = Dict(
        scheme.id => scheme.observers
        for scheme in job.domain_creators
    )
    results = Result[]
    for recipe in job.recipes
        domain = domains[recipe.domain_id]
        observers = observers[recipe.domain_id]
        phenotypes = [job.pheno_dict[indiv_id] for indiv_id in recipe.indiv_ids]
        result = interact(domain, observers, phenotypes)
        push!(results, result)
    end
    return results
end

struct BasicResult{OUT <: Outcome, OBS <: Observation} <: Result
    domain_id::String
    indiv_ids::Vector{Int}
    outcome_set::Vector{OUT}
    observations::Vector{OBS}
end

function interact(
    domain::Domain, 
    observers::Vector{<:Observer},
    phenotypes::Vector{<:Phenotype}
)
    refresh!(domain, observers, phenotypes)
    observe!(domain, observers)
    while is_active(domain)
        next!(domain)
        observe!(domain, observers)
    end
    indiv_ids = [pheno.id for pheno in phenotypes]
    outcome_set = get_outcomes(domain)
    observations = [make_observation(observer) for observer in observers]
    result = BasicResult(
        domain.id, 
        indiv_ids,
        outcome_set, 
        observations
    )
    return result
end

Base.@kwdef struct BasicJobCreator{
    D <: DomainCreator
} <: JobConfiguration
    n_workers::Int = 1
    domain_creators::OrderedDict{String, D} 
end

# Constructor for JobCfg with a default number of workers.
function BasicJobCreator(
    domain_creators::Vector{<:DomainCreator}
)
    domain_creators = OrderedDict(
        scheme.id => scheme for scheme in domain_creators
    )
    return BasicJobCreator(domain_creators, 1)
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
function create_jobs(job_creator::BasicJobCreator, eco::Ecosystem)
    recipes = vcat(
        [
            make_interaction_recipes(scheme, eco) 
            for scheme in values(job_creator.domain_creators)
        ]...
    )
    recipe_partitions = divvy(recipes, job_creator.n_workers)
    pheno_dict = get_pheno_dict(eco)
    jobs = [
        BasicJob(job_creator.domain_creators, pheno_dict, recipe_partition)
        for recipe_partition in recipe_partitions
    ]
    if length(jobs) == 1
        results = perform(jobs[1])
    else
        futures = [remotecall(perform, i, job) for (i, job) in enumerate(jobs)]
        results = [fetch(f) for f in futures]
    end
    return vcat(results...)
end

"""
    InteractionRecipe

Defines a template for an interaction. 

# Fields
- `domain_id::Int`: Identifier for the interaction domain.
- `indiv_ids::Vector{Int}`: Identifiers of individuals participating in the interaction.
"""
struct InteractionRecipe
    domain_id::String
    indiv_ids::Vector{Int}
end

"""
    make_interaction_recipes(domain_id::Int, cfg::DomainCfg, eco::Ecosystem) -> Vector{InteractionRecipe}

Construct interaction recipes for a given domain based on its configuration and an ecosystem.

# Arguments
- `domain_id::Int`: ID of the domain for which the recipes are being generated.
- `cfg::DomainCfg`: The configuration of the domain.
- `eco::Ecosystem`: The ecosystem from which entities are sourced for interactions.

# Returns
- A `Vector` of `InteractionRecipe` instances, detailing pairs of entities to interact.

# Throws
- Throws an `ArgumentError` if the number of entities in the domain configuration isn't 2.
"""
function make_interaction_recipes(
    scheme::DomainCreator, eco::Ecosystem
)
    if length(scheme.species_ids) != 2
        throw(ErrorException("Only two-entity interactions are supported for now."))
    end
    species1 = eco.species[scheme.species_ids[1]]
    species2 = eco.species[scheme.species_ids[2]]
    interaction_ids = scheme.matchmaker(species1, species2)
    interaction_recipes = [
        InteractionRecipe(scheme.id, [id1, id2]) for (id1, id2) in interaction_ids
    ]
    return interaction_recipes
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


