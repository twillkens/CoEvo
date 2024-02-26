module DodoTest

export get_individuals
export DodoTestSpecies, DodoTestSpeciesCreator, create_species, update_species!
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
using ....Interfaces

Base.@kwdef mutable struct DodoTestSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    explorers::Vector{I}
    hillclimbers::Vector{I}
    children::Vector{I}
    retirees::Vector{I}
end

Base.@kwdef mutable struct DodoTestSpeciesCreator <: SpeciesCreator
    id::String
    n_explorers::Int = 100
    max_explorer_age::Int = 1
    max_explorer_temperature::Int = 50
    explorer_temperature_increment_frequency::Int = 5
    max_explorer_samples::Int = 100
    max_hillclimbers::Int = 20
    max_hillclimber_age::Int = 100
    max_hillclimber_temperature::Int = 50
    hillclimber_temperature_increment_frequency::Int = 5
    n_hillclimber_children::Int = 10
    max_retirees::Int = 1000
    max_retiree_samples::Int = 100
end

include("logging.jl")
include("promotion.jl")

function create_species(
    id::String, 
    individual_creator::IndividualCreator, 
    n_explorers::Int, 
    reproducer::Reproducer, 
    state::State
)
    explorers = create_individuals(individual_creator, n_explorers, reproducer, state)
    I = typeof(first(explorers))
    population = copy(explorers)
    species = DodoTestSpecies(id, population, explorers, I[], I[], I[])
    return species
end

function create_species(
    species_creator::DodoTestSpeciesCreator, reproducer::Reproducer, state::State
)
    individual_creator = reproducer.individual_creator 
    n_explorers = species_creator.n_explorers
    id = species_creator.id
    species = create_species(id, individual_creator, n_explorers, reproducer, state)
    return species
end


function create_children(
    parents::Vector{I}, 
    n_children_per_parent::Int,
    reproducer::Reproducer, 
    state::State
) where I <: Individual
    all_children = I[]
    for _ in 1:n_children_per_parent
        children = recombine(reproducer.recombiner, reproducer.mutator, parents, state)
        append!(all_children, children)
    end
    return all_children
end

function create_hillclimber_children(
    species_creator::DodoTestSpeciesCreator, 
    species::DodoTestSpecies, 
    reproducer::Reproducer, 
    state::State
)
    n_children = species_creator.n_hillclimber_children
    parents = species.hillclimbers
    children = create_children(parents, n_children, reproducer, state)
    return children
end

function create_next_explorers(
    species_creator::DodoTestSpeciesCreator, 
    species::DodoTestSpecies, 
    reproducer::Reproducer, 
    state::State
)
    n_explorers = species_creator.n_explorers
    explorers = create_individuals(reproducer.individual_creator, n_explorers, reproducer, state)
    return explorers
end

function age_hillclimbers!(species::DodoTestSpecies)
    for hillclimber in species.hillclimbers
        hillclimber.age += 1
    end
end

function perform_promotions!(
    species::DodoTestSpecies, species_creator::DodoTestSpeciesCreator, evaluation::Evaluation
)
    promote_explorers!(species, evaluation)
    promote_children!(species, evaluation)
    retire_hillclimbers!(species, species_creator, evaluation)
end

function increase_hillclimber_temperature!(species::DodoTestSpecies, species_creator::DodoTestSpeciesCreator)
    for individual in species.hillclimbers
        is_max_temp = individual.temperature >= species_creator.max_hillclimber_temperature
        frequency = species_creator.hillclimber_temperature_increment_frequency
        is_time_to_increase = individual.age % frequency == 0
        if individual.age > 1 && !is_max_temp && is_time_to_increase
            individual.temperature += 1
        end
    end
end

function update_species!(
    species::DodoTestSpecies{I}, 
    species_creator::DodoTestSpeciesCreator, 
    evaluation::Evaluation, 
    reproducer::Reproducer,
    state::State
) where I <: Individual
    perform_promotions!(species, species_creator, evaluation)
    species.children = create_hillclimber_children(species_creator, species, reproducer, state)
    species.explorers = create_next_explorers(species_creator, species, reproducer, state)
    n_retirees_to_sample = min(length(species.retirees), species_creator.max_retiree_samples)
    active_retirees = sample(state.rng, species.retirees, n_retirees_to_sample, replace=false)
    species.population = [species.hillclimbers ; species.children ; species.explorers ; active_retirees]
    age_hillclimbers!(species)
    increase_hillclimber_temperature!(species, species_creator)
    print_info(species)
end


get_all_individuals(species::DodoTestSpecies) = unique(
    [species.children ; species.hillclimbers ; species.explorers ; species.retirees]
)

Base.getindex(species::DodoTestSpecies, id::Int) = begin
    return first(filter(individual -> individual.id == id, get_all_individuals(species)))
end

#function convert_to_dict(species::DodoTestSpecies)
#    dict = Dict(
#        "ID" => species.id,
#        "POPULATION" => Dict(
#            individual.id => convert_to_dict(individual) 
#            for individual in species.population
#        ),
#        "ARCHIVE" => Dict(
#            individual.id => convert_to_dict(individual) 
#            for individual in species.archive
#        ),
#        "ARCHIVE_IDS" => [individual.id for individual in species.archive]
#    )
#    return dict
#end

end
