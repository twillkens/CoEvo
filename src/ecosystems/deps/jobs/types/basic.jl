module Basic

export BasicJob, BasicJobCreator

using DataStructures: OrderedDict


using ..Abstract: Job, JobCreator, Ecosystem, Phenotype

import ..Interfaces: create_jobs



"""
    BasicJob{D <: DomainConfiguration, T} <: Job

Defines a job that orchestrates a set of interactions.

# Fields
- `domain_creators::Vector{D}`: Configurations for interaction domains.
- `pheno_dict::Dict{Int, T}`: Dictionary mapping individual IDs to their phenotypes.
- `recipes::Vector{InteractionRecipe}`: Interaction recipes to be executed in this job.
"""
struct BasicJob{T <: Domain, P <: Phenotype, M <: Match} <: Job
    domains::OrderedDict{String, T}
    phenotypes::Dict{Int, P}
    matches::Vector{M}
end


Base.@kwdef struct BasicJobCreator{T <: Domain} <: JobCreator
    domains::OrderedDict{String, T} 
    n_workers::Int = 1
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
        indiv_id => create_phenotype(species.pheno_creator, indiv.geno)
        for species in values(eco.species)
        for (indiv_id, indiv) in merge(species.pop, species.children)
    )
end

"""
    divvy(items::Vector{T}, njobs::Int) where T

Partition the `items` vector into approximately equal-sized chunks based on the 
specified number of jobs (`njobs`). If the items cannot be evenly divided, 
some partitions might contain an extra item.

# Arguments
- `items::Vector{T}`: A vector of items to be partitioned.
- `njobs::Int`: The number of partitions or jobs required.

# Returns
- A vector of vectors, where each inner vector represents a partition of the items.
"""
function make_partitions(items::Vector{T}, n_partitions::Int) where T
    n = length(items)
    # Base size for each job
    base_size = div(n, n_partitions)
    # Number of jobs that will take an extra item
    extras = n % n_partitions
    partitions = Vector{Vector{T}}()
    start_idx = 1
    for _ in 1:n_partitions
        end_idx = start_idx + base_size - 1
        if extras > 0
            end_idx += 1
            extras -= 1
        end
        push!(partitions, items[start_idx:end_idx])
        start_idx = end_idx + 1
    end
    return partitions
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
    matches = vcat(
        [
            make_matches(domain.matchmaker, eco) 
            for domain in values(job_creator.domains)
        ]...
    )
    match_partitions = make_partitions(matches, job_creator.n_workers)
    pheno_dict = get_pheno_dict(eco)
    jobs = [
        BasicJob(job_creator.domains, pheno_dict, match_partition)
        for match_partition in match_partitions
    ]
    return jobs
end

end
