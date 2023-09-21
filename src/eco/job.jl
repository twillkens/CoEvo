abstract type JobConfiguration end
abstract type Job end 

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

function make_interaction_recipes(domain_id::Int, cfg::DomainCfg, eco::Ecosystem)
    if length(cfg.entities) != 2
        throw(ArgumentError("Only two-entity interactions are supported for now."))
    end
    species1 = eco.species[cfg.pheno_ids[1]]
    species2 = eco.species[cfg.pheno_ids[2]]
    interaction_ids = cfg.matchmaker(species1, species2)
    [InteractionRecipe(domain_id, [id1, id2]) for (id1, id2) in interaction_ids]
end

Base.@kwdef struct EvaluationJob{D <: DomainConfiguration, P <: Phenotype} <: Job
    domain_cfgs::Vector{D}
    pheno_dict::Dict{Int, P}
    recipes::Vector{InteractionRecipe}
end

struct JobCfg{D <: JobConfiguration} <: JobConfiguration
    n_workers::Int
    domain_cfgs::Vector{D}
end


function perform(job::EvaluationJob)
    interaction_results = InteractionResult[]
    for recipe in job.recipes
        domain = job.domains[recipe.domain_id]
        phenos = [job.pheno_dict[indiv_id] for indiv_id in recipe.indiv_ids]
        result = interact(domain.problem, domain.outcome_cfg, recipe.indiv_ids..., phenos...)
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
        EvaluationJob(cfg.domain_cfgs, pheno_dict, recipe_partition)
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