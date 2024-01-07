module Simple

export SimpleEcosystem, SimpleEcosystemCreator
export get_species

import ...Abstract.States: get_species_creators, get_evaluators, get_phenotype_creators
import ...Abstract.States: get_all_species
import ...Individuals: get_individuals
import ...Species: get_species
import ...Evaluators: evaluate
import ..Ecosystems: create_ecosystem

using ...Species: AbstractSpecies
using ...SpeciesCreators: SpeciesCreator, create_species
using ..Ecosystems.Null: NullEcosystem

using ..Ecosystems: Ecosystem, EcosystemCreator

using ...Abstract.States: State, get_ecosystem

struct SimpleEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::Int
    species::Vector{S}
end

get_all_species(ecosystem::SimpleEcosystem) = ecosystem.species

Base.@kwdef mutable struct SimpleEcosystemCreator{S <: SpeciesCreator} <: EcosystemCreator
    id::Int
    species_creators::Vector{S}
end

get_species_creators(
    ecosystem_creator::SimpleEcosystemCreator
) = ecosystem_creator.species_creators

get_evaluators(ecosystem_creator::SimpleEcosystemCreator) = [
    species_creator.evaluator
    for species_creator in get_species_creators(ecosystem_creator)
]

get_phenotype_creators(ecosystem_creator::SimpleEcosystemCreator) = [
    species_creator.phenotype_creator
    for species_creator in get_species_creators(ecosystem_creator)
]

using ...Species: get_population

function create_ecosystem(
    ecosystem_creator::SimpleEcosystemCreator, ::NullEcosystem, state::State
)
    #println("create_ecosystem null")
    all_species = [
        create_species(species_creator, state)
        for species_creator in ecosystem_creator.species_creators
    ]
    #println("popids: ", [individual.id for individual in get_population(all_species[1])])
    new_ecosystem = SimpleEcosystem(ecosystem_creator.id, all_species)
    return new_ecosystem
end

function create_ecosystem(
    ecosystem_creator::SimpleEcosystemCreator, 
    ecosystem::SimpleEcosystem,
    state::State
)

    #println("create_ecosystem not null")
    #all_species = [
    #    create_species(species_creator, species, state)
    #    for (species_creator, species) in zip(
    #        ecosystem_creator.species_creators, 
    #        ecosystem.species
    #    )
    #]
    all_species = create_species(
        ecosystem_creator.species_creators, 
        ecosystem.species, 
        state
    )           
    #println("popids: ", [individual.id for individual in get_population(all_species[1])])
    new_ecosystem = SimpleEcosystem(ecosystem_creator.id, all_species)
    return new_ecosystem
end

function create_ecosystem(
    ecosystem_creator::SimpleEcosystemCreator, state::State
)
    new_ecosystem = create_ecosystem(ecosystem_creator, get_ecosystem(state), state)
    return new_ecosystem
end

using  ...Abstract.States: find_by_id

function get_species(ecosystem::SimpleEcosystem, species_id::String)
    species = find_by_id(ecosystem.species, species_id)
    return species
end

end
