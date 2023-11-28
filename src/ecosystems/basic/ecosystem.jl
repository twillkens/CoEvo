
struct BasicEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::String
    species::Vector{S}
end

Base.@kwdef mutable struct BasicEcosystemCreator{
    S <: SpeciesCreator, 
    J <: JobCreator, 
    P <: Performer,
    C <: StateCreator,
    R <: Reporter,
    A <: Archiver,
} <: EcosystemCreator
    id::String
    trial::Int
    random_number_generator::AbstractRNG
    species_creators::Vector{S}
    job_creator::J
    performer::P
    state_creator::C
    reporters::Vector{R}
    archiver::A
    individual_id_counter::Counter = BasicCounter(0)
    gene_id_counter::Counter = BasicCounter(0)
    garbage_collection_interval::Int = 50
end

function create_ecosystem(ecosystem_creator::BasicEcosystemCreator)
    all_species = [
        create_species(
            species_creator,
            ecosystem_creator.random_number_generator, 
            ecosystem_creator.individual_id_counter, 
            ecosystem_creator.gene_id_counter
        ) 
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