module Basic

export BasicSpecies, get_individuals

import ....Interfaces: get_individuals, get_individuals_to_evaluate, get_individuals_to_perform

using ....Abstract

Base.@kwdef struct BasicSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
end

get_individuals(species::BasicSpecies) = species.population

get_individuals_to_evaluate(species::BasicSpecies) = get_individuals(species)

get_individuals_to_perform(species::BasicSpecies) = get_individuals(species)

end