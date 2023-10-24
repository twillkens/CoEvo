module Basic

export BasicJob, BasicJobCreator

using Random: AbstractRNG

using ..Jobs.Abstract: Job, JobCreator
using ...Ecosystems.Abstract: Ecosystem
using ...Interactions.Abstract: Interaction
using ...Interactions.MatchMakers.Matches.Abstract: Match
using ...Species.Phenotypes.Abstract: Phenotype
using ...Species.Abstract: AbstractSpecies, SpeciesCreator
using ...Species.Phenotypes.Interfaces: create_phenotype
using ...Species.Phenotypes.Abstract: PhenotypeCreator

import ..Jobs.Interfaces: create_jobs
import ...Interactions.MatchMakers.Interfaces: make_matches


struct BasicJob{I <: Interaction, P <: Phenotype, M <: Match} <: Job
    interactions::Dict{String, I}
    phenotypes::Dict{Int, P}
    matches::Vector{M}
end


Base.@kwdef struct BasicJobCreator{I <: Interaction} <: JobCreator
    interactions::Vector{I} 
    n_workers::Int = 1
end


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
- `cfg::JobCfg`: The job configuration detailing interactions and number of workers.
- `eco::Ecosystem`: The ecosystem providing entities for interaction.

# Returns
- A `Vector` of `InteractionResult` detailing outcomes of all interactions executed.
"""


function create_phenotype_dict(
    all_species::Vector{<:AbstractSpecies},
    phenotype_creators::Vector{<:PhenotypeCreator},
)
    phenotype_dict = Dict(
        individual.id => create_phenotype(phenotype_creator, individual.genotype)
        for (species, phenotype_creator) in zip(all_species, phenotype_creators)
        for individual in [species.population; species.children]
    )
    return phenotype_dict
end

function filter_phenotypes_by_matches(
    phenotype_dict::Dict{Int, <:Phenotype}, matches::Vector{<:Match}, 
)
    filtered_phenotypes = Dict(
        individual_id => phenotype_dict[individual_id]
        for match in matches
        for individual_id in match.indiv_ids
    )
    return filtered_phenotypes
end

function make_all_matches(
    job_creator::BasicJobCreator,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AbstractSpecies}
)
    all_matches = vcat(
        [
            make_matches(
                interaction.matchmaker, 
                random_number_generator,
                interaction.id,
                all_species,
                interaction.species_ids
            ) 
            for interaction in job_creator.interactions
        ]...
    )
    return all_matches
end

function make_all_jobs(
    job_creator::BasicJobCreator,
    phenotype_dict::Dict{Int, <:Phenotype},
    match_partitions::Vector{Vector{M}}
) where M <: Match
    interactions = Dict(
        interaction.id => interaction for interaction in job_creator.interactions
    )
    jobs = map(match_partitions) do match_partition
        filtered_phenotype_dict = filter_phenotypes_by_matches(phenotype_dict, match_partition)
        BasicJob(interactions, filtered_phenotype_dict, match_partition)
    end
    return jobs
end

function create_jobs(
    job_creator::BasicJobCreator, 
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AbstractSpecies},
    phenotype_creators::Vector{<:PhenotypeCreator},
)
    all_matches = make_all_matches(job_creator, random_number_generator, all_species)
    match_partitions = make_partitions(all_matches, job_creator.n_workers)
    phenotype_dict = create_phenotype_dict(all_species, phenotype_creators)
    jobs = make_all_jobs(job_creator, phenotype_dict, match_partitions)
    return jobs
end

end
