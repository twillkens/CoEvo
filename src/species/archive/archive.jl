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
    active_archive_ids::Vector{Int}
end

function ArchiveSpecies(id::String, population::Vector{I}) where I <: Individual
    return ArchiveSpecies(id, population, I[], Int[])
end

get_individuals_to_evaluate(species::ArchiveSpecies) = species.population

get_individuals_to_perform(species::ArchiveSpecies) = [
    species.population; 
    [individual for individual in species.archive if individual.id in species.active_archive_ids]
]

end