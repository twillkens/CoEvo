module Simple

export SimpleEcosystem, SimpleEcosystemCreator

import ....Interfaces: create_ecosystem, update_ecosystem!
import ....Interfaces: convert_to_dict, create_from_dict
using ....Abstract: Ecosystem, EcosystemCreator, State, AbstractSpecies
using ....Abstract
using ....Utilities: find_by_id
using ....Interfaces: create_species, update_species!

struct SimpleEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::Int
    all_species::Vector{S}
end

Base.@kwdef struct SimpleEcosystemCreator <: EcosystemCreator end

Base.getindex(ecosystem::SimpleEcosystem, species_id::String) = begin
    return first(filter(species -> species.id == species_id, ecosystem.all_species))
end

function create_ecosystem(::SimpleEcosystemCreator, id::Int, state::State)
    all_species = [
        create_species(state.reproducer.species_creator, species_id, state)
        for species_id in state.reproducer.species_ids
    ]
    all_individuals = [
        individual for species in all_species for individual in species.population
    ]
    all_individual_ids = [individual.id for individual in all_individuals]
    new_ecosystem = SimpleEcosystem(id, all_species)
    return new_ecosystem
end

function update_ecosystem!(
    ecosystem::SimpleEcosystem, 
    ::SimpleEcosystemCreator, 
    evaluations::Vector{<:Evaluation}, 
    state::State
)
    all_individuals = [
        individual for species in ecosystem.all_species for individual in species.population
    ]
    all_individual_ids = [individual.id for individual in all_individuals]
    if length(all_individuals) != length(Set(all_individual_ids))
        println("all_individual_ids = $all_individual_ids")
        error("individual ids are not unique BEFORE")
    end
    for species in ecosystem.all_species
        evaluation = find_by_id(evaluations, species.id)
        update_species!(species, state.reproducer.species_creator, evaluation, state)
    end
    all_individuals = [
        individual for species in ecosystem.all_species for individual in species.population
    ]
    all_individual_ids = [individual.id for individual in all_individuals]
    if length(all_individuals) != length(Set(all_individual_ids))
        println("all_individual_ids = $all_individual_ids")
        error("individual ids are not unique AFTER")
    end
end

function convert_to_dict(ecosystem::SimpleEcosystem)
    dict = Dict(
        "ID" => ecosystem.id,
        "SPECIES" => Dict(
            species.id => convert_to_dict(species) for species in ecosystem.all_species
        )
    )
    return dict
end

function create_from_dict(::SimpleEcosystemCreator, dict::Dict, state::State)
    id = dict["ID"]
    species_dict = dict["SPECIES"]
    all_species = [
        create_from_dict(state.reproducer.species_creator, species_dict, state)
        for species_dict in values(species_dict)
    ]
    sort!(all_species, by = species -> species.id)
    ecosystem = SimpleEcosystem(id, all_species)
    return ecosystem
end

end
