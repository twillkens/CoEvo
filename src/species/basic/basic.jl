module Basic

export BasicSpecies, get_individuals

import ...Individuals: get_individuals
import ...Species: get_individuals_to_evaluate, get_individuals_to_perform

using ...Individuals: Individual
using ..Species: AbstractSpecies

"""
    BasicSpecies{P <: PhenotypeCreator, I <: Individual}

Represents a species population and its offspring.

# Fields
- `id::String`: Unique species identifier.
- `phenotype_creator::P`: Phenotype configuration.
- `population::OrderedDict{Int, I}`: Current population.
- `children::OrderedDict{Int, I}`: Offspring of the population.
"""
Base.@kwdef struct BasicSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    children::Vector{I}
end

function get_individuals(species::BasicSpecies, ids::Vector{Int})
    all_individuals = [species.population ; species.children]
    individuals = get_individuals(all_individuals, ids)
    return individuals
end

function get_individuals(species::BasicSpecies)
    individuals = [species.population ; species.children]
    return individuals
end

function get_individuals_to_evaluate(species::BasicSpecies)
    individuals = get_individuals(species)
    return individuals
end

function get_individuals_to_perform(species::BasicSpecies)
    individuals = get_individuals(species)
    return individuals
end

end