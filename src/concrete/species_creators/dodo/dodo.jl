module Dodo

export get_individuals
export DodoSpecies, DodoSpeciesCreator, create_species, update_species!
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

Base.@kwdef mutable struct DodoSpecies{I <: Individual} <: AbstractSpecies
    id::String
    explorers::Vector{I}
    hillclimbers::Vector{I}
    children::Vector{I}
    retirees::Vector{I}
    population::Vector{I}
    temperature_dict::Dict{Int, Int}
    age_dict::Dict{Int, Int}
    #lazy_time::Dict{Int, Int}
end

function recombine_and_mutate!(
    temperature_dict::Dict{Int, Int},
    parents::Vector{<:Individual}, 
    reproducer::Reproducer, 
    state::State
)
    children = recombine(reproducer.recombiner, parents, state)
    for child in children
        temperature = max(temperature_dict[child.parent_id] ÷ 5, 1)
        for _ in 1:temperature
            mutate!(reproducer.mutator, child, reproducer, state)
        end
    end
    return children
end

Base.@kwdef mutable struct DodoSpeciesCreator <: SpeciesCreator
    id::String
    n_population::Int = 100
    max_mutations::Int = 100
end

function create_species(
    species_creator::DodoSpeciesCreator, reproducer::Reproducer, state::State
)
    individual_creator = reproducer.individual_creator 
    explorers = create_individuals(individual_creator, species_creator.n_population, reproducer, state)
    temperature_dict = Dict(individual.id => 1 for individual in explorers)
    age_dict = Dict{Int, Int}()
    #lazy_time = Dict(individual.id => 0 for individual in parents)
    I = typeof(explorers[1])
    population = copy(explorers)
    species = DodoSpecies(
        species_creator.id, explorers, I[], I[], I[], population, temperature_dict, age_dict
    )
    return species
end

function increment_mutations!(species::DodoSpecies, species_creator::DodoSpeciesCreator)
    for (id, n_mutation) in species.temperature_dict
        n_mutation = min(n_mutation + 1, species_creator.max_mutations)
        species.temperature_dict[id] = n_mutation
    end
end

function age_individuals!(species::DodoSpecies, evaluation::Evaluation)
    for (id, age) in species.age_dict
        if id in evaluation.matrix.row_ids
            species.age_dict[id] = age + 1
        else
            species.age_dict[id] = age + 1
        end
    end
end

function validate_species(species::DodoSpecies, species_creator::DodoSpeciesCreator)
    #if length(species.population) != species_creator.n_population
    #    error("Population size is $(length(species.population)), but should be $(species_creator.n_population)")
    #end
    parent_ids = [parent.id for parent in species.hillclimbers]
    for child in species.children
        if !(child.parent_id in parent_ids)
            error("Child parent_id $(child.parent_id) not in parent_ids: $(parent_ids)")
        end
    end
    temp_keys = collect(keys(species.temperature_dict))
    hillclimber_ids = [hillclimber.id for hillclimber in species.hillclimbers]
    explorer_ids = [explorer.id for explorer in species.explorers]
    expected_ids = [hillclimber_ids ; explorer_ids]
    if sort(temp_keys) != sort(expected_ids)
        error("Temperature keys $(temp_keys) do not match expected ids $(expected_ids)")
    end
end

function promote_explorers!(species::DodoSpecies, evaluation::Evaluation)
    for id in evaluation.explorer_to_promote_ids
        individual = species[id]
        species.temperature_dict[id] = 1
        species.age_dict[id] = 0
        filter!(ind -> ind.id != id, species.explorers)
        filter!(ind -> ind.id != id, species.retirees)
        push!(species.hillclimbers, individual)
    end
end

function promote_children!(species::DodoSpecies, evaluation::Evaluation)
    for id in evaluation.children_to_promote_ids
        individual = species[id]
        species.temperature_dict[id] = 1
        species.age_dict[id] = 0
        filter!(ind -> ind.id != id, species.children)
        delete!(species.temperature_dict, individual.parent_id)
        delete!(species.age_dict, individual.parent_id)
        filter!(ind -> ind.id != individual.parent_id, species.hillclimbers)
        push!(species.hillclimbers, individual)
    end
end

const MAX_AGE = 100

function demote_hillclimbers!(species::DodoSpecies, evaluation::Evaluation)
    for id in evaluation.hillclimbers_to_demote_ids
        individual = species[id]
        species.temperature_dict[id] = 0
        delete!(species.age_dict, id)
        filter!(ind -> ind.id != id, species.hillclimbers)
        push!(species.explorers, individual)
    end
    for (id, age) in species.age_dict
        if age >= MAX_AGE
            individual = species[id]
            #species.temperature_dict[id] = 0
            delete!(species.temperature_dict, id)
            delete!(species.age_dict, id)
            filter!(ind -> ind.id != id, species.hillclimbers)
            push!(species.retirees, individual)
            if length(species.retirees) > 100
                popfirst!(species.retirees)
            end
        end
    end
end

function print_info(species::DodoSpecies)
    info = []
    for individual in species.hillclimbers
        temp = species.temperature_dict[individual.id]
        max_dimension = argmax(individual.genotype.genes)
        v = round(individual.genotype.genes[max_dimension], digits=2)
        age = round(species.age_dict[individual.id] / MAX_AGE, digits=2)
        #i = (max_dimension, v, temp)
        i = (max_dimension, v, age)
        i = round(mean(individual.genotype.genes); digits=2)
        push!(info, i)
    end
    sort!(info, by = x -> x[1])
    println("hc_info = ", info)
    info = []
    for individual in species.children
        max_dimension = argmax(individual.genotype.genes)
        v = round(individual.genotype.genes[max_dimension], digits=2)
        i = (max_dimension, v)
        i = round(mean(individual.genotype.genes); digits=2)
        push!(info, i)
    end
    sort!(info, by = x -> x[1])
    println("children_info = ", info)
    info = []
    for individual in species.explorers
        max_dimension = argmax(individual.genotype.genes)
        v = round(individual.genotype.genes[max_dimension], digits=2)
        i = (max_dimension, v)
        i = round(mean(individual.genotype.genes); digits=2)
        push!(info, i)
    end
    sort!(info, by = x -> x[1])
    println("explorer_info = ", info)
end

function update_species!(
    species::DodoSpecies{I}, 
    species_creator::DodoSpeciesCreator, 
    evaluation::Evaluation, 
    reproducer::Reproducer,
    state::State
) where I <: Individual
    promote_explorers!(species, evaluation)
    promote_children!(species, evaluation)
    demote_hillclimbers!(species, evaluation)
    species.children = recombine_and_mutate!(species.temperature_dict, species.hillclimbers, reproducer, state)
    species.explorers = recombine_and_mutate!(species.temperature_dict, species.explorers, reproducer, state)
    for explorer in species.explorers
        species.temperature_dict[explorer.id] = species.temperature_dict[explorer.parent_id]
        delete!(species.temperature_dict, explorer.parent_id)
    end
    guaranteed = [species.hillclimbers ; species.children]
    #n_explorers_to_sample = max(0, species_creator.n_population - length(guaranteed))
    #current_explorers = sample(state.rng, species.explorers, n_explorers_to_sample, replace=false)
    current_explorers = copy(species.explorers)
    donors = filter(x -> rand() > 100, current_explorers)
    if length(donors) > 0 && length(species.hillclimbers) > 0
        filter!(ind -> !(ind in donors), current_explorers)
        extra_parents = sample(state.rng, species.hillclimbers, length(donors), replace=true)
        extra_children = recombine_and_mutate!(species.temperature_dict, extra_parents, reproducer, state)
        species.population = [guaranteed ; current_explorers ; extra_children]
    else
        species.population = [guaranteed ; current_explorers]
    end
    n_retirees_to_sample = min(length(species.retirees), 50)
    retirees = sample(state.rng, species.retirees, n_retirees_to_sample, replace=false)
    species.population = [species.population ; retirees]
    increment_mutations!(species, species_creator)
    age_individuals!(species, evaluation)
    validate_species(species, species_creator)
    print_info(species)
end


get_all_individuals(species::DodoSpecies) = unique(
    [species.children ; species.hillclimbers ; species.explorers ; species.population]
)

Base.getindex(species::DodoSpecies, id::Int) = begin
    return first(filter(individual -> individual.id == id, get_all_individuals(species)))
end

function convert_to_dict(species::DodoSpecies)
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
#    species::DodoSpecies, species_creator::DodoSpeciesCreator, evaluation::Evaluation
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