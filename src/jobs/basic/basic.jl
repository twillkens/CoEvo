module Basic

export BasicJob, BasicJobCreator

import ..Jobs: create_jobs
import ...Species: create_phenotype_dict

using Random: AbstractRNG
using ...Phenotypes: Phenotype, PhenotypeCreator, create_phenotype
using ...Individuals: get_individuals
using ...Species: AbstractSpecies, get_species_with_ids 
using ...SpeciesCreators: SpeciesCreator
using ...Matches: Match
using ...MatchMakers: make_matches
using ...Interactions: Interaction
using ..Jobs: Job, JobCreator

struct BasicJob{I <: Interaction, P <: Phenotype, M <: Match} <: Job
    interactions::Dict{String, I}
    phenotypes::Dict{Int, P}
    matches::Vector{M}
end

Base.@kwdef struct BasicJobCreator{I <: Interaction} <: JobCreator
    interactions::Vector{I} 
    n_workers::Int = 1
end

#function create_phenotype_dict(
#    all_species::Vector{<:AbstractSpecies},
#    phenotype_creators::Vector{<:PhenotypeCreator},
#)
#    phenotype_dict = Dict(
#        individual.id => create_phenotype(phenotype_creator, individual)
#        for (species, phenotype_creator) in zip(all_species, phenotype_creators)
#        for individual in get_individuals(species)
#    )
#    return phenotype_dict
#end

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
                get_species_with_ids(all_species, interaction.species_ids),
            ) 
            for interaction in job_creator.interactions
        ]...
    )
    return all_matches
end

function create_phenotype_dict(
    all_species::Vector{<:AbstractSpecies},
    phenotype_creators::Vector{<:PhenotypeCreator},
    matches::Vector{<:Match},
)
    all_match_ids = Int[]
    for match in matches
        append!(all_match_ids, match.individual_ids)
    end
    all_necessary_ids = Set(all_match_ids)
    phenotype_dict = create_phenotype_dict(all_species, phenotype_creators, all_necessary_ids)

    return phenotype_dict
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

function filter_phenotypes_by_matches(
    phenotype_dict::Dict{Int, P}, matches::Vector{<:Match}, 
) where P <: Phenotype
    filtered_phenotypes = Dict{Int, P}(
        individual_id => phenotype_dict[individual_id]
        for match in matches
        for individual_id in match.individual_ids
    )
    return filtered_phenotypes
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
    phenotype_dict = create_phenotype_dict(all_species, phenotype_creators, all_matches)
    match_partitions = make_partitions(all_matches, job_creator.n_workers)
    #phenotype_dict = create_phenotype_dict(all_species, phenotype_creators)
    jobs = make_all_jobs(job_creator, phenotype_dict, match_partitions)
    return jobs
end

end
