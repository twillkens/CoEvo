module Archive

export ArchiveSpecies, get_individuals, get_individual

import ....Interfaces: get_individuals, get_individuals_to_evaluate, get_individuals_to_perform
import ....Interfaces: convert_to_dict
using ....Abstract
using ....Utilities: find_by_id

Base.@kwdef mutable struct ArchiveSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    archive::Vector{I}
    active_archive_individuals::Vector{I}
end

function ArchiveSpecies(id::String, population::Vector{I}) where I <: Individual
    return ArchiveSpecies(id, population, I[], I[])
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

function convert_to_dict(species::ArchiveSpecies)
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
        "ARCHIVE_IDS" => [individual.id for individual in species.active_archive_individuals]
    )
    return dict
end

end