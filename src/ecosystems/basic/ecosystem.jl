
struct BasicEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::String
    species::Vector{S}
end

Base.@kwdef struct BasicEcosystemCreator{
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
    runtime_reporter::RuntimeReporter = RuntimeReporter()
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