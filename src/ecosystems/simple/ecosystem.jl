using ...States.Global: GlobalState
using ...Abstract: Experiment, State

struct BasicEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::String
    species::Vector{S}
end

Base.@kwdef mutable struct SimpleEcosystemCreator{
    S <: SpeciesCreator, 
    J <: JobCreator, 
    P <: Performer,
    C <: StateCreator,
    R <: Reporter,
    A <: Archiver,
} <: EcosystemCreator
    id::String
    species_creators::Vector{S}
    job_creator::J
    performer::P
    state_creator::C
    reporters::Vector{R}
    archiver::A
end

function create_ecosystem(ecosystem_creator::SimpleEcosystemCreator, state::State)
    all_species = [
        create_species(species_creator, state)
        for species_creator in ecosystem_creator.species_creators
    ]
    ecosystem = BasicEcosystem(ecosystem_creator.id, all_species)
    return ecosystem
end

function get_individuals(ecosystem::BasicEcosystem)
    all_individuals = vcat([get_individuals(species) for species in ecosystem.species]...)
    return all_individuals
end

function get_individuals(ecosystem::BasicEcosystem, ids::Vector{Int})
    all_individuals = get_individuals(ecosystem)
    individuals = filter(individual -> individual.id in ids, all_individuals)
    if length(individuals) != length(ids)
        throw(ErrorException("Could not find all individuals with ids $ids"))
    end
    return individuals
end


function get_species(ecosystem::BasicEcosystem, species_id::String)
    for species in ecosystem.species
        if species.id == species_id
            return species
        end
    end
    throw(ErrorException("Could not find species with id $species_id"))
end