module Simple

export SimpleEcosystem, SimpleEcosystemCreator

import ....Interfaces: create_ecosystem, update_ecosystem!
import ....Interfaces: convert_to_dictionary, convert_from_dictionary
using ....Abstract: Ecosystem, EcosystemCreator, State, AbstractSpecies
using ....Abstract
using ....Interfaces: create_species, update_species!

struct SimpleEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::Int
    all_species::Vector{S}
end

Base.@kwdef mutable struct SimpleEcosystemCreator <: EcosystemCreator end

function create_ecosystem(::SimpleEcosystemCreator, id::Int, state::State)
    all_species = [
        create_species(state.species_creator, species_id, state)
        for species_id in state.species_ids
    ]
    new_ecosystem = SimpleEcosystem(id, all_species)
    return new_ecosystem
end

function update_ecosystem!(ecosystem::SimpleEcosystem, state::State)
    for species in ecosystem.all_species
        update_species!(state.species_creator, species, state)
    end
end

function convert_to_dictionary(ecosystem::SimpleEcosystem)
    return Dict(
        "ID" => ecosystem.id,
        "S" => Dict(species.id => convert_to_dictionary(species) for species in ecosystem.all_species)
    )
end

function convert_from_dictionary(
    ::SimpleEcosystemCreator, 
    species_creator::SpeciesCreator,
    individual_creator::IndividualCreator,
    genotype_creator::GenotypeCreator,
    phenotype_creator::PhenotypeCreator,
    dict::Dict
)
    id = dict["ID"]
    species_dict = dict["S"]
    all_species = [
        convert_from_dictionary(
            species_creator, 
            individual_creator,
            genotype_creator,
            phenotype_creator,
            species_dict
        )
        for species_dict in values(species_dict)
    ]
    sort!(all_species, by = species -> species.id)
    ecosystem = SimpleEcosystem(id, all_species)
    return ecosystem
end

end
