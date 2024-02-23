module Basic

export BasicSpeciesCreator, create_species, update_species!, create_children
export get_elites, get_parent_records, validate_population

import ....Interfaces: get_individuals, create_species, update_species!

using Random: AbstractRNG
using ....Abstract
using ....Interfaces
using ...Species.Basic: BasicSpecies

Base.@kwdef struct BasicSpeciesCreator <: SpeciesCreator
    id::String
    n_population::Int
    n_parents::Int
    n_children::Int
    n_elites::Int
end

function create_species(
    species_creator::BasicSpeciesCreator, reproducer::Reproducer, state::State
)
    population = create_individuals(
        reproducer.individual_creator, species_creator.n_population, reproducer, state
    )
    species = BasicSpecies(species_creator.id, population)
    return species
end

function get_elites(species_creator::BasicSpeciesCreator, evaluation::Evaluation,)
    I = typeof(evaluation.records[1].individual)
    elite_records = evaluation.records[1:species_creator.n_elites]
    elites = I[record.individual for record in elite_records]
    return elites
end

function get_parent_records(species_creator::BasicSpeciesCreator, evaluation::Evaluation)
    parent_records = evaluation.records[1:species_creator.n_parents]
    return parent_records
end

function validate_population(
    population::Vector{<:Individual}, species_creator::BasicSpeciesCreator
)
println("N_POPULATION_EXPECTED = ", species_creator.n_population)
    if length(population) != species_creator.n_population
        n_population = species_creator.n_population
        expected = species_creator.n_population
        error("population length = $n_population, expected = $expected")
    end
end

function create_children(
    species_creator::BasicSpeciesCreator,
    evaluation::Evaluation,
    selector::Selector,
    recombiner::Recombiner,
    mutator::Mutator,
    reproducer::Reproducer,
    state::State
)
    parent_records = get_parent_records(species_creator, evaluation)
    selections = select(selector, parent_records, state)
    children = recombine(recombiner, selections, state)
    mutate!(mutator, children, reproducer, state)
    return children
end

create_children(
    species_creator::BasicSpeciesCreator, 
    evaluation::Evaluation, 
    reproducer::Reproducer, 
    state::State
) = create_children(
    species_creator, evaluation, reproducer.selector, reproducer.recombiner, reproducer.mutator, 
    reproducer, state
)

function update_species!(
    species::BasicSpecies, 
    species_creator::BasicSpeciesCreator,
    evaluation::Evaluation,
    reproducer::Reproducer,
    state::State
) 
    elites = get_elites(species_creator, evaluation)
    children = create_children(species_creator, evaluation, reproducer, state)
    new_population = [elites; children]
    validate_population(new_population, species_creator)
    empty!(species.population)
    append!(species.population, new_population)
end

end
