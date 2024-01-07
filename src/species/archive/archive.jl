module Archive

export ArchiveSpecies, get_individuals

import ...Individuals: get_individuals
import ...Species: get_individuals_to_evaluate, get_individuals_to_perform

using ...Individuals: Individual
using ..Species: AbstractSpecies

Base.@kwdef struct ArchiveSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    archive::Vector{I}
end

function ArchiveSpecies(id::String, population::Vector{I}) where I <: Individual
    return ArchiveSpecies(id, population, I[])
end

get_individuals_to_evaluate(species::ArchiveSpecies) = species.population

get_individuals_to_perform(species::ArchiveSpecies) = [species.population; species.archive]

end