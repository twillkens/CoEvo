module Archive

export ArchiveSpeciesCreator, create_species, update_species!, update_archive!
export add_individuals_to_archive!, update_active_archive_individuals!, update_population!

import ....Interfaces: get_individuals, create_species, update_species!
import ....Interfaces: create_from_dict
using ....Abstract
using ....Interfaces

using StatsBase: sample
using ...Species.Archive: ArchiveSpecies
using ...Evaluators.ScalarFitness
using ...Evaluators.NSGAII
using ...Evaluators.Distinction: DistinctionEvaluation

Base.@kwdef struct ArchiveSpeciesCreator <: SpeciesCreator
    n_population::Int
    n_parents::Int
    n_children::Int
    n_elites::Int
    n_archive::Int
    archive_interval::Int
    max_archive_length::Int
    max_archive_matches::Int
end

function create_species(species_creator::ArchiveSpeciesCreator, id::String, state::State)
    n_population = species_creator.n_population
    individual_creator = state.reproducer.individual_creator
    population = create_individuals(individual_creator, n_population, state)
    #TODO: hack for numbers game
    if id == "B"
    #if length(species_creator.max_archive_matches ) > 0
        archive = create_individuals(individual_creator, species_creator.max_archive_matches, state)
        active_archive_individuals = copy(archive)
    else
        T = typeof(first(population))
        archive = T[]
        active_archive_individuals = T[]
    end

    species = ArchiveSpecies(id, population, archive, active_archive_individuals)
    return species
end

function add_individuals_to_archive!(
    species_creator::ArchiveSpeciesCreator,
    species::ArchiveSpecies,
    candidates::Vector{<:Individual},
)
    candidate_ids = Set([candidate.id for candidate in candidates])

    filter!(individual -> individual.id ∉ candidate_ids, species.archive)
    append!(species.archive, candidates)

    while length(species.archive) > species_creator.max_archive_length
        # eject the first elements to maintain size
        deleteat!(species.archive, 1)
    end
end

using StatsBase: sample

function add_individuals_to_archive!(
    species_creator::ArchiveSpeciesCreator, 
    species::ArchiveSpecies, 
    evaluation::DistinctionEvaluation,
)
    elite_records = evaluation.population_outcome_records[1:species_creator.n_archive]
    elites = [record.individual for record in elite_records]

    println("adding $(length(elites)) individuals to archive")
    add_individuals_to_archive!(species_creator, species, elites)
end



function update_active_archive_individuals!(
    species_creator::ArchiveSpeciesCreator, 
    species::ArchiveSpecies, 
    evaluation::DistinctionEvaluation,
    state::State
)
    empty!(species.active_archive_individuals)
    candidates = [
        individual for individual in species.archive 
            if individual ∉ species.population
    ]
    new_archive_individuals = sample(
        state.rng, candidates, species_creator.max_archive_matches; replace = false
    )
    append!(species.active_archive_individuals, new_archive_individuals)
    if length(species.active_archive_individuals) > species_creator.max_archive_matches
        println("species_creator = $species_creator")
        println("species = $species")
        println("evaluation = $evaluation")
        error("active archive individuals > max_archive_matches")
    end
end
#function update_active_archive_individuals!(
#    species_creator::ArchiveSpeciesCreator, 
#    species::ArchiveSpecies, 
#    evaluation::DistinctionEvaluation,
#    state::State
#)
#    n_half = species_creator.max_archive_matches ÷ 2
#    n_remove = max(0, length(species.active_archive_individuals) - n_half)
#    to_remove = [
#        record.individual for record in 
#        reverse(evaluation.active_archive_distinction_records)[1:n_remove]
#    ]
#    candidates = [
#        individual for individual in species.archive 
#            if individual ∉ [species.population]
#    ]
#    filter!(individual -> individual ∉ to_remove, species.active_archive_individuals)
#    n_archive_matches = min(n_half, length(candidates))
#    new_archive_individuals = sample(state.rng, candidates, n_archive_matches; replace = false)
#    empty!(species.active_archive_individuals)
#    append!(species.active_archive_individuals, new_archive_individuals)
#    if length(species.active_archive_individuals) > species_creator.max_archive_matches
#        println("species_creator = $species_creator")
#        println("species = $species")
#        println("evaluation = $evaluation")
#        error("active archive individuals > max_archive_matches")
#    end
#end


function update_archive!(
    species_creator::ArchiveSpeciesCreator, 
    species::ArchiveSpecies, 
    evaluation::Evaluation,
    state::State
)
    if species.id == "B"
    #if species_creator.max_archive_length > 0
        add_individuals_to_archive!(species_creator, species, evaluation)
        update_active_archive_individuals!(species_creator, species, evaluation, state)
    end
end

using ...Evaluators.Distinction: DistinctionEvaluation

function update_population!(
    species::ArchiveSpecies, 
    species_creator::ArchiveSpeciesCreator, 
    evaluation::DistinctionEvaluation,
    state::State
) 
    parent_records = evaluation.population_outcome_records[1:species_creator.n_parents]
    parents = [
        record.individual for record in
        select(state.reproducer.selector, parent_records, species_creator.n_children, state)
    ]
    new_children = recombine(state.reproducer.recombiner, parents, state)
    for child in new_children
        mutate!(state.reproducer.mutator, child, state)
    end
    if species_creator.n_elites > 0
        elite_records = evaluation.population_outcome_records[1:species_creator.n_elites]
        elites = [record.individual for record in elite_records]
        new_population = [elites ; new_children]
    else
        new_population = new_children
    end
    if length(species.archive) > 0
        candidates = [indiv for indiv in species.archive if indiv ∉ [species.population ; species.active_archive_individuals]]
        n_sample = min(length(candidates), 10)
        println("sampling $n_sample individuals from archive and adding to population")
        if n_sample > 0
            random_individuals = sample(state.rng, candidates, n_sample; replace = false)
            new_population[end - n_sample + 1:end] = random_individuals
        end

    end
    ids = [individual.id for individual in new_population]
    if length(ids) != length(Set(ids))
        error("Duplicate IDs in new population")
    end
    empty!(species.population)
    append!(species.population, new_population)
end

function update_species!(
    species::ArchiveSpecies, 
    species_creator::ArchiveSpeciesCreator, 
    evaluation::Evaluation,
    state::State
) 
    n_population_before = length(species.population)
    update_archive!(species_creator, species, evaluation, state)
    update_population!(species, species_creator, evaluation, state)
    archive_ids = [individual.id for individual in species.active_archive_individuals]
    population_ids = [individual.id for individual in species.population]
    if length(union(archive_ids, population_ids)) != length(archive_ids) + length(population_ids)
        error("Duplicate IDs in archive and population")
    end
    n_population_after = length(species.population)
    if n_population_after != n_population_before
        error("Population size changed from $n_population_before to $n_population_after")
    end
end

function create_from_dict(::ArchiveSpeciesCreator, dict::Dict, state::State)
    individual_creator = state.reproducer.individual_creator
    id = dict["ID"]
    population = [
        create_from_dict(individual_creator, individual_dict, state)
        for individual_dict in values(dict["POPULATION"])
    ]
    I = typeof(first(population))
    if haskey(dict, "ARCHIVE")
        archive = I[
            create_from_dict(individual_creator, individual_dict, state)
            for individual_dict in values(dict["ARCHIVE"])
        ]
        active_ids = Set(dict["ARCHIVE_IDS"])
        active_individuals = I[individual for individual in archive if individual.id in active_ids]
    else
        archive = I[]
        active_individuals = I[]
    end
    species = ArchiveSpecies(id, population, archive, active_individuals)
    return species
end

end