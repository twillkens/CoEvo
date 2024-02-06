module Distinguisher


export get_individuals

import ....Interfaces: get_individuals, get_individuals_to_evaluate, get_individuals_to_perform
import ....Interfaces: convert_to_dict
using ....Abstract
using ....Interfaces
using ....Utilities: find_by_id

Base.@kwdef mutable struct DistinguisherSpecies{I <: Individual} <: AbstractSpecies
    id::String
    archive::Vector{I}
    population::Vector{I}
    hillclimbers::Vector{I}
    n_mutations::Dict{Int, Int}
end

Base.@kwdef mutable struct DistinguisherSpeciesCreator <: SpeciesCreator
    n_population::Int
    max_archive_size::Int = 100
    max_clusters::Int = 10
    max_mutations::Int = 100
end

function get_other_individuals(species::DistinguisherSpecies, state::State)
    error("Not implemented")
end

function get_cluster_assignments(matrix::SortedDict{Int, Vector{Float64}}, state::State)
    samples = collect(values(matrix))
    clustering_result = get_fast_global_clustering_result(
        state.rng, samples, max_clusters = species_creator.max_clusters
    )
    id_map = Dict(i => id for (i, (id, _)) in enumerate(matrix))
    cluster_indices = clustering_result.cluster_indices
    cluster_assignments = Dict{Int, Int}()
    for (cluster_id, members) in enumerate(cluster_indices)
        for member_index in members
            id = id_map[member_index]
            cluster_assignments[id] = cluster_id
        end
    end
    return cluster_assignments
end

function get_cluster_assignments(matrix::OutcomeMatrix, state::State)
    matrix = get_sorted_dict(matrix)
    assignments = get_cluster_assignments(matrix, state)
    return assignments
end

using DataStructures

# the distinguisher species serves as the "test" or "parasite" counterpart to the "learner/host"
# species, the members of which we want to improve performance across all underlying objectives
# as such, we want the members of this population to maintain the cleanest "gradient" for 
# learning, which means that we want to maintain a diverse set of tests that probe for 
# distinctions between the members of the host species.
# this is a coevolutionary algorithm that is an extension of the DELPHI and Discovery of Search
# Objectives algorithm. the idea is to approximate the "pareto-hillclimbing" evaluator archi
# ture of DELPHI, but allow it to jump "discrete" gaps in the genotype/phenotype mapping
# by increasing the temperature over time.
function update_population!(
    species::DistinguisherSpecies, species_creator::DistinguisherSpeciesCreator, state::State
)
    others = get_other_individuals(species, state)
    # the distinction matrix is calculated row by row for each evaluator.
    # it is n_evaluators X (n_learners * (n_learners - 1)) \div 2
    # a distinction entry for an evalutor is 1 if the result of two learner pairs is different
    distinction_matrix = make_distinction_matrix(species.population, others, state.results)
    # we filter out evaluators who fail to make any distinctions.
    # it may be the case that an evaluator is "too hard" (no learner successes) or "too easy"
    # (all learner successes). in either case, we want to remove these evaluators from the
    # pool
    matrix = filter_zero_rows(distinction_matrix)
    # the hillclimber vector is empty at the start of the algorithm.
    # if a hillclimber is not found in the distinction matrix, that means that it once
    # found distinctions at least in the previous generation, and hence is "useful." 
    # and so we add it to the archive
    for hc in species.hillclimbers
        if !(hc.id in matrix.row_ids)
            push!(species.archive, hc)
            filter!(individual -> individual.id != hc.id, species.hillclimbers)
        end
    end
    # if no distinctions have been found then continue
    if length(matrix) > 0
        # we use global K-means clustering that automatically "discovers" the number of informative
        # clusters present in the data.
        clustering_result = get_fast_global_clustering_result(
            state.rng, matrix, max_clusters = species_creator.max_clusters
        )
        for cluster in clustering_result
            individuals = get_individuals(cluster)
            ids = [individual.id for individual in individuals]
            # we wish to identify the dominance hierarchy of the individuals in the cluster
            records = [
                NSGAIIRecord(id = id, individual = species[id], tests = matrix[id]) 
                for id in ids
            ]
            nsga_sort!(records, Maximize())
            # the criteria for usurping a hillclimber is if an explorer/child in the cluster strictly 
            # dominates its parent with respect to distinctions
            rank_one_individuals = [record.individual for record in records if record.rank == 1]
            other_individuals = setdiff(individuals, rank_one_individuals)
            hillclimber_is_best = false
            for hc in species.hillclimbers
                if hc in rank_one_individuals
                    hillclimber_is_best = true
                    break
                elseif hc in other_individuals
                    # if the hillclimber is no longer the best, then we add it to the archive,
                    # as it previously was useful
                    push!(species.archive, hc)
                    filter!(individual -> individual.id != hc.id, species.hillclimbers)
                    # individuals that are added to the archive are reset to 0 mutations
                    # the number of mutations to perform increases over the time
                    # the individual spends in the archive. this is a form of "temperature"
                    species.n_mutations[hc.id] = 0
                end
            end
            if !hillclimber_is_best
                # if the hillclimber is no longer the best, we select a random
                # nondominated individual from the first rank to serve as the new hillclimber
                new_hillclimber = rand(state.rng, rank_one_individuals)
                # the mutation temperature is reset for the hillclimber
                # we would like it to explore locally around the new best
                species.n_mutations[new_hillclimber.id] = 0
                push!(species.hillclimbers, new_hillclimber)
                # delete from the archive if it is present
                filter!(individual -> individual.id != new_hillclimber.id, species.archive)
            end
        end
        children = []
        # each hillclimber spawns a child according to its temperature
        for hc in species.hillclimbers
            child = first(recombine(CloneRecombiner(), [hc], state))
            n_mutations = species.n_mutations[hc.id]
            for _ in 1:n_mutations
                mutate!(state.reproducer.mutator, child, state)
            end
            push!(children, child)
        end
    else
        # if the matrix is empty, then all hillclimbers have been relieved and so
        # the children vector is empty
        children = []
    end
    # we wish to sample from the archive 
    # this gives a measure of stability to the evolving learner population, who are restested
    # against previously distinctive tests
    n_archive_samples = (species_creator.n_population - length(species.hillclimbers) * 2) ÷ 2
    active_archive = sample(state.rng, species.archive, n_archive_samples, replace = false)
    # we also generate an "explorer" child from the archive which aims to explore
    # the space of distinctions with wider range. this could rediscover lost objectives
    # or find new distant ones, as the temperature of the explorer increases with age
    for individual in active_archive
        child = first(recombine(CloneRecombiner(), [individual], state))
        n_mutations = species.n_mutations[individual.id]
        for _ in 1:n_mutations
            mutate!(state.reproducer.mutator, child, state)
        end
        push!(children, child)
    end

    # the learner population will be subjected to all vs. all evaluations vs. the new 
    # population of the distinguisher species
    species.population = [species.hillclimbers ; active_archive ; children]
    if length(species.population) != species_creator.n_population
        error("Population size is $(length(species.population)), but should be $(species_creator.n_population)")
    end
    # trim archive if needed, ejecting oldest individuals first
    while length(species.archive) > species_creator.max_archive_size
        id = species.archive[1].id
        delete!(species.n_mutations, id)
        popfirst!(species.archive)
    end
    # the number of mutations to perform increases over time
    for (id, n_mutation) in species.n_mutations
        n_mutation = min(n_mutation + 1, species_creator.max_mutations)
        species.n_mutations[id] = n_mutation
    end
end

get_all_individuals(species::DistinguisherSpecies) = unique(
    [species.population ; species.archive ; species.hillclimbers]
)

get_individuals_to_perform(species::DistinguisherSpecies) = species.population

Base.getindex(species::DistinguisherSpecies, id::Int) = begin
    return first(filter(individual -> individual.id == id, get_all_individuals(species)))
end

function convert_to_dict(species::DistinguisherSpecies)
    dict = Dict(
        "ID" => species.id,
        "POPULATION" => Dict(
            individual.id => convert_to_dict(individual) 
            for individual in species.population
        ),
        "ARCHIVE" => Dict(
            individual.id => convert_to_dict(individual) 
            for individual in species.archive
        ),
        "ARCHIVE_IDS" => [individual.id for individual in species.active_archive_individuals]
    )
    return dict
end

end