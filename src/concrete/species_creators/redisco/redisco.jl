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
    phylogenetic_graph::PhylogeneticGraph
end

function RediscoSpecies(id::String, archive::Vector{I}, population::Vector{I}) where I
    temperature_dict = Dict(individual.id => 1 for individual in archive)
    graph = PhylogeneticGraph{Int}()
    for individual in archive
        add_node!(graph, individual.id)
    end
    for individual in population
        add_node!(graph, individual.parent_id, individual.id)
    end
    species = RediscoSpecies(id, population, I[], archive, temperature_dict, graph)
    return species
end

Base.@kwdef mutable struct RediscoSpeciesCreator <: SpeciesCreator
    id::String
    n_population::Int = 100
    max_archive_size::Int = 500
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
    empty!(species.hillclimbers)
    new_hillclimbers = [
        individual for individual in get_all_individuals(species) 
            if individual.id in evaluation.new_hillclimber_ids
    ]
    for individual in new_hillclimbers
        push!(species.hillclimbers, individual)
        species.temperature_dict[individual.id] = 0
    end
    if length(species.hillclimbers) != length(evaluation.new_hillclimber_ids)
        println("new_hillclimber_ids = ", evaluation.new_hillclimber_ids)
        println("species_hillclimbers_ids = ", [individual.id for individual in species.hillclimbers])
        error("Hillclimbers not found.")
    end
end

function update_archive!(
    species::RediscoSpecies, species_creator::RediscoSpeciesCreator, evaluation::Evaluation
)
    retired_hillclimbers = [
        individual for individual in species.population
            if individual.id in evaluation.retired_hillclimber_ids
    ]
    for individual in retired_hillclimbers
        if length(species.archive) == species_creator.max_archive_size
            if individual.parent_id in keys(species.phylogenetic_graph.child_mapping)
                to_delete_id = get_oldest_ancestor(species.phylogenetic_graph, individual.parent_id)
            else
                println("parent $(individual.parent_id) not found in graph for individual $(individual.id)")
                to_delete_id = first(species.archive).id
            end
            delete_node!(species.phylogenetic_graph, to_delete_id)
            filter!(ind -> ind.id != to_delete_id, species.archive)
            if individual.parent_id in keys(species.phylogenetic_graph.child_mapping)
                add_node!(species.phylogenetic_graph, individual.parent_id, individual.id)
            else
                add_node!(species.phylogenetic_graph, individual.id)
            end
        end
        push!(species.archive, individual) 
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
    archive_ids = [individual.id for individual in species.archive]
    for (id, n_mutation) in species.temperature_dict
        n_mutation = min(n_mutation + 1, species_creator.max_mutations)
        species.temperature_dict[id] = n_mutation
        if id in archive_ids && n_mutation == species_creator.max_mutations
            delete_node!(species.phylogenetic_graph, id)
            filter!(ind -> ind.id != id, species.archive)
        end
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
    update_hillclimbers!(species, evaluation)
    update_archive!(species, species_creator, evaluation)
    
    n_archive_samples = (species_creator.n_population - length(species.hillclimbers) * 2) ÷ 2
    active_archive = sample(state.rng, species.archive, n_archive_samples, replace = false)
    archive_clones = recombine(reproducer.recombiner, active_archive, state)
    parents = [species.hillclimbers ; active_archive]
    children = recombine_and_mutate!(species, parents, reproducer, state)
    species.population = [species.hillclimbers ; archive_clones ; children]
    #trim_archive!(species, species_creator, evaluation, state.rng)
    increment_mutations!(species, species_creator)
    validate_species(species, species_creator)
    #for individual in species.hillclimbers
    #    genotype = round.(individual.genotype.genes; digits = 3)
    #    println("Hillclimber $(individual.id): $(genotype)")
    #end
    temperatures = Int[]
    for individual in species.archive
        temp = species.temperature_dict[individual.id]
        push!(temperatures, temp)
    end
    println("temps = $temperatures")
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