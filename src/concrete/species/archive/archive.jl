module Archive

export ArchiveSpecies, get_individuals, get_individual

import ....Interfaces: get_individuals, get_individuals_to_evaluate, get_individuals_to_perform
import ....Interfaces: convert_to_dictionary
using ....Abstract
using ....Utilities: find_by_id

Base.@kwdef mutable struct ArchiveSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    archive::Vector{I}
    active_archive_individuals::Vector{I}
end

function ArchiveSpecies(id::String, population::Vector{I}) where I <: Individual
    return ArchiveSpecies(id, population, I[], Int[])
end

get_individuals_to_evaluate(species::ArchiveSpecies) = species.population

get_individuals_to_perform(species::ArchiveSpecies) = [
    species.population; species.active_archive_individuals
]

get_individual(species::ArchiveSpecies, id::Int) = find_by_id(
    [species.population; species.archive], id
)

get_individuals(species::ArchiveSpecies) = [species.population; species.archive]

Base.getindex(species::ArchiveSpecies, id::Int) = begin
    return first(filter(individual -> individual.id == id, get_individuals(species)))
end

function convert_to_dictionary(species::ArchiveSpecies)
    return Dict(
        "ID" => species.id,
        "P" => Dict(individual.id => convert_to_dictionary(individual) for individual in species.population),
        "A" => Dict(individual.id => convert_to_dictionary(individual) for individual in species.archive),
        "A_IDS" => [individual.id for individual in species.active_archive_individuals]
    )
end

end