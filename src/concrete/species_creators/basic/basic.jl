module Basic

export BasicSpeciesCreator

import ....Interfaces: get_individuals, create_species

using Random: AbstractRNG
using ....Abstract
using ....Interfaces
using ...Species.Basic: BasicSpecies

Base.@kwdef struct BasicSpeciesCreator <: SpeciesCreator
    n_population::Int
    n_parents::Int
    n_children::Int
    n_elites::Int
end

function create_species(species_creator::BasicSpeciesCreator, id::String, state::State)
    population = create_individuals(
        state.individual_creator, species_creator.n_population, state
    )
    species = BasicSpecies(id, population)
    return species
end

function update_population!(
    species_creator::BasicSpeciesCreator, 
    species::BasicSpecies, 
    evaluation::Evaluation,
    state::State
) 
    ordered_ids = [record.id for record in evaluation.records]
    parent_ids = Set(ordered_ids[1:species_creator.n_parents])
    parent_set = [individual for individual in species.population if individual.id in parent_ids]
    parents = select(state.selector, parent_set, evaluation, state)
    new_children = recombine(state.recombiner, parents, state)
    mutate!(state.mutator, new_children, state)
    if species_creator.n_elites > 0
        elite_ids = [record.id for record in evaluation.records[1:species_creator.n_elites]]
        elites = [individual for individual in species.population if individual.id in elite_ids]
        new_population = [elites ; new_children]
    else
        new_population = new_children
    end
    empty!(species.population)
    append!(species.population, new_population)
end

function update_species!(
    species_creator::BasicSpeciesCreator, 
    species::BasicSpecies, 
    evaluation::Evaluation,
    state::State
) 
    n_population_before = length(species.population)
    update_population!(species_creator, species, evaluation, state)
    n_population_after = length(species.population)
    if n_population_after != n_population_before
        error("Population size changed from $n_population_before to $n_population_after")
    end
end

end