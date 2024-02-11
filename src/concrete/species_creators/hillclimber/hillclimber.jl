module HillClimber

export get_individuals
export HillClimberSpecies, HillClimberSpeciesCreator, create_species, update_species!
export recombine_and_mutate!
export increment_mutations!
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

Base.@kwdef mutable struct HillClimberSpecies{I <: Individual} <: AbstractSpecies
    id::String
    parents::Vector{I}
    children::Vector{I}
    population::Vector{I}
    temperature_dict::Dict{Int, Int}
    preferred::Vector{Int}
end

function recombine_and_mutate!(
    temperature_dict::Dict{Int, Int},
    parents::Vector{<:Individual}, 
    reproducer::Reproducer, 
    state::State
)
    children = recombine(reproducer.recombiner, parents, state)
    for child in children
        temperature = temperature_dict[child.parent_id]
        for _ in 1:temperature
            mutate!(reproducer.mutator, child, reproducer, state)
        end
    end
    return children
end

Base.@kwdef mutable struct HillClimberSpeciesCreator <: SpeciesCreator
    id::String
    n_population::Int = 100
    max_mutations::Int = 100
end

function create_species(
    species_creator::HillClimberSpeciesCreator, reproducer::Reproducer, state::State
)
    n_parents = species_creator.n_population ÷ 2
    individual_creator = reproducer.individual_creator 
    parents = create_individuals(individual_creator, n_parents, reproducer, state)
    temperature_dict = Dict(individual.id => 1 for individual in parents)
    children = recombine_and_mutate!(temperature_dict, parents, reproducer, state)
    population = [parents ; children]
    species = HillClimberSpecies(
        species_creator.id, parents, children, population, temperature_dict, Int[]
    )
    return species
end

function increment_mutations!(species::HillClimberSpecies, species_creator::HillClimberSpeciesCreator)
    for (id, n_mutation) in species.temperature_dict
        n_mutation = min(n_mutation + 1, species_creator.max_mutations)
        species.temperature_dict[id] = n_mutation
    end
end

function validate_species(species::HillClimberSpecies, species_creator::HillClimberSpeciesCreator)
    if length(species.population) != species_creator.n_population
        error("Population size is $(length(species.population)), but should be $(species_creator.n_population)")
    end
    parent_ids = [parent.id for parent in species.parents]
    for child in species.children
        if !(child.parent_id in parent_ids)
            error("Child parent_id $(child.parent_id) not in parent_ids: $(parent_ids)")
        end
    end
end

function update_species!(
    species::HillClimberSpecies{I}, 
    species_creator::HillClimberSpeciesCreator, 
    evaluation::Evaluation, 
    reproducer::Reproducer,
    state::State
) where I <: Individual
    setdiff!(species.preferred, evaluation.to_defer_ids)
    for to_promote_id in evaluation.to_promote_ids
        individual = species[to_promote_id]
        species.temperature_dict[to_promote_id] = 0
        delete!(species.temperature_dict, individual.parent_id)
        filter!(ind -> ind.id != individual.parent_id, species.parents)
        push!(species.parents, individual)
        push!(species.preferred, to_promote_id)
    end
    increment_mutations!(species, species_creator)

    species.children = recombine_and_mutate!(species.temperature_dict, species.parents, reproducer, state)
    for (i, parent) in enumerate(species.parents)
        if species.temperature_dict[parent.id] == species_creator.max_mutations
            new_parent = species.children[i]
            species.temperature_dict[new_parent.id] = 1
            new_child = recombine_and_mutate!(species.temperature_dict, [new_parent], reproducer, state)[1]
            species.parents[i] = new_parent
            species.children[i] = new_child
            delete!(species.temperature_dict, parent.id)

        end
    end
    species.population = [species.parents ; species.children]
    
    validate_species(species, species_creator)
    info = []
    for individual in species.parents
        temp = species.temperature_dict[individual.id]
        max_dimension = argmax(individual.genotype.genes)
        v = round(individual.genotype.genes[max_dimension], digits=2)
        i = (temp, max_dimension, v)
        push!(info, i)
    end
    println("info = ", info)
    info = []
    for individual in species.children
        #temp = species.temperature_dict[individual.id]
        max_dimension = argmax(individual.genotype.genes)
        v = round(individual.genotype.genes[max_dimension], digits=2)
        i = (max_dimension, v)
        push!(info, i)
    end
    println("info = ", info)
end

#function update_species!(
#    species::HillClimberSpecies{I}, 
#    species_creator::HillClimberSpeciesCreator, 
#    evaluation::Evaluation, 
#    reproducer::Reproducer,
#    state::State
#) where I <: Individual
#    parents = I[]
#    for (parent, child, winner_id) in zip(species.parents, species.children, evaluation.winner_ids)
#        if winner_id == child.id
#            species.temperature_dict[child.id] = 0
#            delete!(species.temperature_dict, parent.id)
#            winner = child
#        else 
#            winner = parent
#        end
#        push!(parents, winner)
#    end
#    increment_mutations!(species, species_creator)
#    children = recombine_and_mutate!(species.temperature_dict, parents, reproducer, state)
#    species.parents = parents
#    species.children = children
#    species.population = [parents ; children]
#    
#    validate_species(species, species_creator)
#    info = []
#    for individual in species.parents
#        temp = species.temperature_dict[individual.id]
#        max_dimension = argmax(individual.genotype.genes)
#        i = (temp, max_dimension)
#        push!(info, i)
#    end
#    println("info = ", info)
#end

get_all_individuals(species::HillClimberSpecies) = unique(
    species.population 
)

Base.getindex(species::HillClimberSpecies, id::Int) = begin
    return first(filter(individual -> individual.id == id, get_all_individuals(species)))
end

function convert_to_dict(species::HillClimberSpecies)
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
#    species::HillClimberSpecies, species_creator::HillClimberSpeciesCreator, evaluation::Evaluation
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