module SpreadDodo

export get_individuals
export SpreadDodoSpecies, SpreadDodoSpeciesCreator, create_species, update_species!
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
using ...Individuals.Dodo: DodoIndividual
using ....Interfaces

Base.@kwdef mutable struct SpreadDodoSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    parents::Vector{I}
    children::Vector{I}
    explorers::Vector{I}
    retirees::Vector{I}
end

Base.@kwdef mutable struct SpreadDodoSpeciesCreator <: SpeciesCreator
    id::String
    n_parents::Int = 100
    n_children::Int = 100
    n_explorers::Int = 100
    max_retirees::Int = 1000
    max_retiree_samples::Int = 100
end

include("logging.jl")

function initialize_children(
    parents::Vector{I}, 
    n_children::Int,
    reproducer::Reproducer, 
    state::State
) where I <: DodoIndividual
    all_parents = Vector{Vector{I}}()
    for _ in 1:n_children
        selected_parents = sample(state.rng, parents, 2, replace=false)
        push!(all_parents, selected_parents)
    end
    children = recombine(reproducer.recombiner, reproducer.mutator, all_parents, state)
    return children
end
function create_species(
    id::String, 
    individual_creator::IndividualCreator, 
    n_parents::Int,
    n_children::Int,
    n_explorers::Int, 
    reproducer::Reproducer, 
    state::State
)
    parents = create_individuals(individual_creator, n_parents, reproducer, state)
    children = initialize_children(parents, n_children, reproducer, state)
    explorers = create_individuals(individual_creator, n_explorers, reproducer, state)
    I = typeof(first(explorers))
    retirees = I[]
    population = [parents ; children ; explorers]
    species = SpreadDodoSpecies(id, population, parents, children, explorers, retirees)
    return species
end

function create_species(
    species_creator::SpreadDodoSpeciesCreator, reproducer::Reproducer, state::State
)
    individual_creator = reproducer.individual_creator 
    n_parents = species_creator.n_parents
    n_children = species_creator.n_children
    n_explorers = species_creator.n_explorers
    id = species_creator.id
    species = create_species(
        id, individual_creator, n_parents, n_children, n_explorers, reproducer, state
    )
    return species
end

function promote_new_parents!(species::SpreadDodoSpecies, evaluation::Evaluation)
    for id in evaluation.cluster_leaders
        individual = species[id]
        filter!(parent -> parent.id != id, species.parents)
        filter!(explorer -> explorer.id != id, species.explorers)
        filter!(retiree -> retiree.id != id, species.retirees)
        push!(species.parents, individual)
    end
end

function update_retirees!(species::SpreadDodoSpecies, species_creator::SpreadDodoSpeciesCreator)
    while length(species.parents) > species_creator.n_parents
        retiree = popfirst!(species.parents)
        push!(species.retirees, retiree)
        if length(species.retirees) > species_creator.max_retirees
            popfirst!(species.retirees)
        end
    end
end

function update_children!(
    species::SpreadDodoSpecies, evaluation::Evaluation, reproducer::Reproducer, state::State
)
    records = [record for record in evaluation.records if record.individual in species.parents]
    selections = select(reproducer.selector, records, state)
    species.children = recombine(reproducer.recombiner, reproducer.mutator, selections, state)
end

function update_explorers!(
    species::SpreadDodoSpecies, 
    species_creator::SpreadDodoSpeciesCreator, 
    reproducer::Reproducer, 
    state::State
)
    for explorer in species.explorers
        mutate!(reproducer.mutator, explorer,  reproducer, state)
    end
    n_explorers_to_create = species_creator.n_explorers - length(species.explorers)
    new_explorers = create_individuals(
        reproducer.individual_creator, n_explorers_to_create, reproducer, state
    )
    append!(species.explorers, new_explorers)
end

function update_population!(
    species::SpreadDodoSpecies, species_creator::SpreadDodoSpeciesCreator, state::State
)
    n_retirees_to_sample = min(length(species.retirees), species_creator.max_retiree_samples)
    active_retirees = sample(state.rng, species.retirees, n_retirees_to_sample, replace=false)
    species.population = [species.parents ; species.children ; species.explorers ; active_retirees]
end

function update_species!(
    species::SpreadDodoSpecies{I}, 
    species_creator::SpreadDodoSpeciesCreator, 
    evaluation::Evaluation, 
    reproducer::Reproducer,
    state::State
) where I <: Individual
    promote_new_parents!(species, evaluation)
    update_retirees!(species, species_creator, )
    update_children!(species, evaluation, reproducer, state)
    update_explorers!(species, species_creator, reproducer, state)
    update_population!(species, species_creator, state)
    print_info(species)
end

get_all_individuals(species::SpreadDodoSpecies) = unique(
    [species.parents ; species.children ; species.explorers ; species.retirees]
)

Base.getindex(species::SpreadDodoSpecies, id::Int) = begin
    return first(filter(individual -> individual.id == id, get_all_individuals(species)))
end

#function convert_to_dict(species::SpreadDodoSpecies)
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
