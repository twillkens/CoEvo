module Simple

export SimpleJob, SimpleJobCreator

import ....Interfaces: create_jobs

using ....Abstract
using ....Utilities: find_by_id
using ....Interfaces
using Random: AbstractRNG

struct SimpleJob{I <: Interaction, P <: Phenotype, M <: Match} <: Job
    interactions::Dict{String, I}
    phenotypes::Dict{Int, P}
    matches::Vector{M}
end

Base.@kwdef struct SimpleJobCreator <: JobCreator
    n_workers::Int = 1
end

function make_all_matches(::SimpleJobCreator, ecosystem::Ecosystem, state::State)
    all_matches = [
        make_matches(
            state.matchmaker, 
            interaction.id,
            find_by_id(ecosystem.all_species, interaction.species_ids),
            state
        ) 
        for interaction in state.interactions
    ]
    all_matches = vcat(all_matches...)
    return all_matches
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

function get_ids(matches::Vector{<:Match})
    ids = Set(
        (species_id, individual_id)
        for match in matches
        for (species_id, individual_id) in zip(match.species_ids, match.individual_ids)
    )
    return ids
end

function get_phenotype_dict(ecosystem::Ecosystem, ids::Set{Tuple{String, Int}})
    pairs = map(collect(ids)) do (species_id, individual_id)
        species = ecosystem[species_id]
        individual = species[individual_id]
        return individual.id => individual.phenotype
    end
    phenotype_dict = Dict(pairs)
    return phenotype_dict
end

function create_jobs(job_creator::SimpleJobCreator, ecosystem::Ecosystem, state::State)
    all_matches = make_all_matches(job_creator, ecosystem, state)
    match_partitions = make_partitions(all_matches, job_creator.n_workers)
    interactions = Dict(
        interaction.id => interaction for interaction in state.interactions
    )
    jobs = map(match_partitions) do match_partition
        ids = get_ids(match_partition)
        phenotype_dict = get_phenotype_dict(ecosystem, ids)
        SimpleJob(interactions, phenotype_dict, match_partition)
    end
    return jobs
end

end
