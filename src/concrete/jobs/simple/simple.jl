module Simple

export SimpleJob, SimpleJobCreator

import ....Interfaces: create_jobs, make_all_matches

using ....Abstract
using ....Utilities: find_by_id
using ....Interfaces
using ...Ecosystems.MaxSolve
using Random: AbstractRNG
using ...Matches.Basic: BasicMatch

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
            state.simulator.matchmaker, 
            interaction.id,
            find_by_id(ecosystem.all_species, interaction.species_ids),
            state
        ) 
        for interaction in state.simulator.interactions
    ]
    all_matches = vcat(all_matches...)
    return all_matches
end

## TODO: maxsolve matchmaker

function make_all_matches(
    ::SimpleJobCreator,
    ecosystem::MaxSolveEcosystem,
    state::State
)
    all_learners = [
        ecosystem.learner_population ; ecosystem.learner_children ; ecosystem.learner_archive
    ]
    all_learner_ids = unique([learner.id for learner in all_learners])
    all_tests = [
        ecosystem.test_population ; ecosystem.test_children ; ecosystem.test_archive
    ]
    all_test_ids = unique([test.id for test in all_tests])
    matches = BasicMatch[]
    matrix = ecosystem.payoff_matrix
    for learner_id in all_learner_ids
        for test_id in all_test_ids
            #if !(learner_id in matrix.row_ids) || !(test_id in matrix.column_ids)
                match = BasicMatch("A", (learner_id, test_id), ("L", "T"))
                push!(matches, match)
            #end
        end
    end
    #println("matches = ", [match.individual_ids for match in matches])
    return matches
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

using Serialization

function get_phenotype_dict(ecosystem::Ecosystem, ids::Set{Tuple{String, Int}})
    pairs = map(collect(ids)) do (species_id, individual_id)
        species = ecosystem[species_id]
        individual = species[individual_id]
        return individual.id => individual.phenotype
    end
    phenotype_dict = Dict(pairs)
    return phenotype_dict
end

function get_phenotype_dict(ecosystem::MaxSolveEcosystem, ids::Set{Tuple{String, Int}})
    pairs = map(collect(ids)) do (species_id, individual_id)
        individual = ecosystem[individual_id]
        return individual.id => individual.phenotype
    end
    phenotype_dict = Dict(pairs)
    return phenotype_dict
end

function create_jobs(job_creator::SimpleJobCreator, ecosystem::Ecosystem, state::State)
    all_matches = make_all_matches(job_creator, ecosystem, state)
    match_partitions = make_partitions(all_matches, job_creator.n_workers)
    interactions = Dict(
        interaction.id => interaction for interaction in state.simulator.interactions
    )
    jobs = map(match_partitions) do match_partition
        ids = get_ids(match_partition)
        phenotype_dict = get_phenotype_dict(ecosystem, ids)
        SimpleJob(interactions, phenotype_dict, match_partition)
    end
    return jobs
end

end
