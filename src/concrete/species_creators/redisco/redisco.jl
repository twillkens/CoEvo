module Redisco

export get_individuals
export RediscoSpecies, RediscoSpeciesCreator, create_species, update_species!
export archive_hillclimbers!, promote_explorers!, recombine_and_mutate!
export trim_archive!, increment_mutations!
export get_all_individuals, convert_to_dict

import ....Interfaces: get_individuals, get_individuals_to_evaluate, get_individuals_to_perform
import ....Interfaces: convert_to_dict, create_species, update_species!
using ....Abstract
using ....Interfaces
using ....Utilities: find_by_id
using ...Recombiners.Clone: CloneRecombiner
using DataStructures
using StatsBase
using Random: shuffle!

include("phylogeny.jl")

Base.@kwdef mutable struct RediscoSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    hillclimbers::Vector{I}
    archive::Vector{I}
    temperature_dict::Dict{Int, Int}
    age_dict::Dict{Int, Int}
    phylogenetic_graph::PhylogeneticGraph
end

function RediscoSpecies(id::String, archive::Vector{I}, population::Vector{I}) where I
    temperature_dict = Dict(individual.id => 1 for individual in archive)
    age_dict = Dict(individual.id => 0 for individual in archive)
    graph = PhylogeneticGraph{Int}()
    for individual in archive
        add_node!(graph, individual.id)
    end
    #for individual in population
    #    add_node!(graph, individual.parent_id, individual.id)
    #end
    species = RediscoSpecies(id, population, I[], archive, temperature_dict, age_dict, graph)
    return species
end

Base.@kwdef mutable struct RediscoSpeciesCreator <: SpeciesCreator
    id::String
    n_population::Int = 100
    max_archive_size::Int = 100
    max_archive_age::Int = 500
    max_mutations::Int = 100
end

function create_species(
    species_creator::RediscoSpeciesCreator, reproducer::Reproducer, state::State
)
    n_population = species_creator.n_population
    individual_creator = reproducer.individual_creator 
    archive = create_individuals(individual_creator, n_population, reproducer, state)
    population = recombine(reproducer.recombiner, archive, state)
    species = RediscoSpecies(species_creator.id, archive, population)
    return species
end


function update_hillclimbers!(species::RediscoSpecies, evaluation::Evaluation)
    println("new_hillclimber_ids = $(evaluation.new_hillclimber_ids)")
    new_hillclimbers = [
        individual for individual in get_all_individuals(species) 
            if individual.id in evaluation.new_hillclimber_ids
    ]
    current_hillclimber_ids = [individual.id for individual in species.hillclimbers]
    empty!(species.hillclimbers)
    for individual in new_hillclimbers
        push!(species.hillclimbers, individual)
        if individual.id ∉ current_hillclimber_ids
            species.temperature_dict[individual.id] = 0
        end
    end
    if length(species.hillclimbers) != length(evaluation.new_hillclimber_ids)
        println("new_hillclimber_ids = ", evaluation.new_hillclimber_ids)
        println("species_hillclimbers_ids = ", [individual.id for individual in species.hillclimbers])
        error("Hillclimbers not found.")
    end
end
using Serialization

function archive_hillclimber!(
    species::RediscoSpecies, species_creator::RediscoSpeciesCreator, individual::Individual, 
)
    species.temperature_dict[individual.id] = 1
    species.age_dict[individual.id] = 0
    if length(species.archive) == species_creator.max_archive_size
        parent = [
            archiv_indiv for archiv_indiv in species.archive 
                if archiv_indiv.id == individual.parent_id
        ]
        if length(parent) != 0
            to_delete = first(parent)
            filter!(ind -> ind.id != to_delete.id, species.archive)
            delete!(species.temperature_dict, to_delete.id)
            delete!(species.age_dict, to_delete.id)
            push!(species.archive, individual) 
        else
            #println("individual = ", individual.id)
            #serialize("test/redisco/species.jls", species)
            #error("Parent not found in archive.")
            #to_delete = first(species.archive)
            #filter!(ind -> ind.id != to_delete.id, species.archive)
            #delete!(species.temperature_dict, to_delete.id)
            #delete!(species.age_dict, to_delete.id)
            #push!(species.archive, individual) 
        end
    else
        push!(species.archive, individual) 
    end
end

function update_archive!(
    species::RediscoSpecies, species_creator::RediscoSpeciesCreator, evaluation::Evaluation
)
    retired_hillclimbers = [
        individual for individual in species.hillclimbers
            if individual.id in evaluation.retired_hillclimber_ids
    ]
    for individual in retired_hillclimbers
        archive_hillclimber!(species, species_creator, individual)
    end
    retired_children = [
        individual for individual in species.population
            if individual.id in evaluation.retired_hillclimber_ids &&
                individual.id ∉ [ind.id for ind in species.hillclimbers]
    ]
    for individual in retired_children
        archive_hillclimber!(species, species_creator, individual)
    end
end

function recombine_and_mutate!(
    species::RediscoSpecies, parents::Vector{<:Individual}, reproducer::Reproducer, state::State
)
    children = recombine(reproducer.recombiner, parents, state)
    for child in children
        temperature = species.temperature_dict[child.parent_id]
        for _ in 1:temperature
            mutate!(reproducer.mutator, child, reproducer, state)
        end
    end
    return children
end


function increment_mutations!(species::RediscoSpecies, species_creator::RediscoSpeciesCreator)
    for (id, n_mutation) in species.temperature_dict
        n_mutation = min(n_mutation + 1, species_creator.max_mutations)
        species.temperature_dict[id] = n_mutation
    end
end

function increment_ages!(species::RediscoSpecies, species_creator::RediscoSpeciesCreator)
    for (id, age) in species.age_dict
        age += 1
        if age >= species_creator.max_archive_age
            filter!(ind -> ind.id != id, species.archive)
            delete!(species.temperature_dict, id)
            delete!(species.age_dict, id)
        end
        species.age_dict[id] = age 
    end
end

function validate_species(species::RediscoSpecies, species_creator::RediscoSpeciesCreator)
    if length(species.population) != species_creator.n_population
        error("Population size is $(length(species.population)), but should be $(species_creator.n_population)")
    end
end

function update_species!(
    species::RediscoSpecies, 
    species_creator::RediscoSpeciesCreator, 
    evaluation::Evaluation, 
    reproducer::Reproducer,
    state::State
)
    increment_ages!(species, species_creator)
    update_hillclimbers!(species, evaluation)
    update_archive!(species, species_creator, evaluation)
    
    n_archive_samples = (species_creator.n_population - length(species.hillclimbers) * 2) ÷ 2
    n_archive_samples = min(n_archive_samples, length(species.archive))
    active_archive = sample(state.rng, species.archive, n_archive_samples, replace = false)
    archive_clones = recombine(reproducer.recombiner, active_archive, state)
    parents = [species.hillclimbers ; active_archive]
    children = recombine_and_mutate!(species, parents, reproducer, state)
    species.population = [species.hillclimbers ; archive_clones ; children]
    n_extra_mutants = species_creator.n_population - length(species.population)
    extra_parents = sample(state.rng, species.archive, n_extra_mutants, replace = true)
    extra_mutants = recombine_and_mutate!(species, extra_parents, reproducer, state)
    append!(species.population, extra_mutants)
    
    
    #trim_archive!(species, species_creator, evaluation, state.rng)
    increment_mutations!(species, species_creator)
    validate_species(species, species_creator)
    #for individual in species.hillclimbers
    #    genotype = round.(individual.genotype.genes; digits = 3)
    #    println("Hillclimber $(individual.id): $(genotype)")
    #end
    info = []
    for individual in species.archive
        temp = species.temperature_dict[individual.id]
        age = species.age_dict[individual.id]
        max_dimension = argmax(individual.genotype.genes)
        i = (temp, age, max_dimension)
        push!(info, i)
    end
    println("info = ", info)
end

get_all_individuals(species::RediscoSpecies) = unique(
    [species.population ; species.archive ; species.hillclimbers]
)

Base.getindex(species::RediscoSpecies, id::Int) = begin
    return first(filter(individual -> individual.id == id, get_all_individuals(species)))
end

function convert_to_dict(species::RediscoSpecies)
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
        "ARCHIVE_IDS" => [individual.id for individual in species.archive]
    )
    return dict
end

end

#function update_archive!(
#    species::RediscoSpecies, species_creator::RediscoSpeciesCreator, evaluation::Evaluation
#)
#    retired_hillclimbers = [
#        individual for individual in species.population
#            if individual.id in evaluation.retired_hillclimber_ids
#    ]
#    for individual in retired_hillclimbers
#        species.temperature_dict[individual.id] = 1
#        species.age_dict[individual.id] = 0
#        if length(species.archive) == species_creator.max_archive_size
#            if individual.parent_id in keys(species.phylogenetic_graph.child_mapping)
#                to_delete_id = get_oldest_ancestor(species.phylogenetic_graph, individual.parent_id)
#                delete_node!(species.phylogenetic_graph, to_delete_id)
#                filter!(ind -> ind.id != to_delete_id, species.archive)
#                if to_delete_id == individual.parent_id
#                    add_node!(species.phylogenetic_graph, individual.id)
#                else
#                    add_node!(species.phylogenetic_graph, individual.parent_id, individual.id)
#                end
#                push!(species.archive, individual) 
#            else
#                to_delete_id = first([
#                    relative.id for relative in species.archive 
#                    if relative.parent_id == individual.parent_id
#                ])
#                delete_node!(species.phylogenetic_graph, to_delete_id)
#                filter!(ind -> ind.id != to_delete_id, species.archive)
#                add_node!(species.phylogenetic_graph, individual.id)
#                push!(species.archive, individual) 
#            end
#        else
#            if individual.parent_id in keys(species.phylogenetic_graph.child_mapping)
#                add_node!(species.phylogenetic_graph, individual.parent_id, individual.id)
#            else
#                add_node!(species.phylogenetic_graph, individual.id)
#            end
#            push!(species.archive, individual) 
#        end
#    end
#end