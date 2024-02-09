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

Base.@kwdef mutable struct RediscoSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    hillclimbers::Vector{I}
    archive::Vector{I}
    temperature_dict::Dict{Int, Int}
end

function RediscoSpecies(id::String, population::Vector{I}) where I
    temperature_dict = Dict(individual.id => 1 for individual in population)
    archive = copy(population)
    species = RediscoSpecies(id, population, I[], archive, temperature_dict)
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
    population = create_individuals(individual_creator, n_population, reproducer, state)
    species = RediscoSpecies(species_creator.id, population)
    return species
end

function archive_hillclimbers!(species::RediscoSpecies, evaluation::Evaluation)
    for individual in species.hillclimbers
        if !(individual.id in evaluation.hillclimber_ids)
            if individual in species.archive
                error("Hillclimber $(individual.id) is in the archive")
            end
            push!(species.archive, individual)
            filter!(ind -> ind.id != individual.id, species.hillclimbers)
            species.temperature_dict[individual.id] = 0
        end
    end
end

function promote_explorers!(species::RediscoSpecies, evaluation::Evaluation)
    for individual in species.archive
        if individual.id in evaluation.hillclimber_ids
            push!(species.hillclimbers, individual)
            filter!(ind -> ind.id != individual.id, species.archive)
            species.temperature_dict[individual.id] = 0
        end
    end
end

function recombine_and_mutate!(
    species::RediscoSpecies, parents::Vector{<:Individual}, reproducer::Reproducer, state::State
)
    children = recombine(reproducer.recombiner, parents, state)
    for (parent, child) in zip(parents, children)
        temperature = species.temperature_dict[parent.id]
        for _ in 1:temperature
            mutate!(reproducer.mutator, child, reproducer, state)
        end
    end
    return children
end

function trim_archive!(species::RediscoSpecies, species_creator::RediscoSpeciesCreator)
    while length(species.archive) > species_creator.max_archive_size
        id = species.archive[1].id
        delete!(species.temperature_dict, id)
        popfirst!(species.archive)
    end
end

function increment_mutations!(species::RediscoSpecies, species_creator::RediscoSpeciesCreator)
    for (id, n_mutation) in species.temperature_dict
        n_mutation = min(n_mutation + 1, species_creator.max_mutations)
        species.temperature_dict[id] = n_mutation
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
    archive_hillclimbers!(species, evaluation)
    promote_explorers!(species, evaluation)
    
    n_archive_samples = (species_creator.n_population - length(species.hillclimbers) * 2) ÷ 2
    active_archive = sample(state.rng, species.archive, n_archive_samples, replace = false)
    parents = [species.hillclimbers ; active_archive]
    children = recombine_and_mutate!(species, parents, reproducer, state)
    species.population = [parents ; children]
    trim_archive!(species, species_creator)
    increment_mutations!(species, species_creator)
    validate_species(species, species_creator)
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