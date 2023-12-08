export BasicCoevolutionaryState, BasicCoevolutionaryStateCreator, create_species

using Base: @kwdef
using ...Jobs: JobCreator
using ...Performers: Performer
using ...SpeciesCreators.Basic: BasicSpeciesCreator

@kwdef struct BasicCoevolutionaryState <: State
    id::String
    random_number_generator::AbstractRNG
    trial::Int
    generation::Int  # Generation number
    species_creators::Vector{<:SpeciesCreator}  # Species creators
    job_creator::JobCreator  # Job creator
    performer::Performer  # Performer
    last_reproduction_time::Float64  # Time spent on reproduction in the last generation
    evaluation_time::Float64  # Time spent on evaluation in the last generation
    individual_id_counter::Counter  # Counter for generating unique individual IDs
    gene_id_counter::Counter  # Counter for generating unique gene IDs
    species::Vector{<:AbstractSpecies}  # Species in the ecosystem
    individual_outcomes::Dict{Int, Dict{Int, Float64}}  # Processed outcomes for each individual
    evaluations::Vector{<:Evaluation}  # Species evaluations based on the results
    observations::Vector{<:Observation}  # Extracted observations from results
end

@kwdef struct BasicCoevolutionaryStateCreator <: StateCreator end

function create_species(
    species_creators::Vector{<:BasicSpeciesCreator}, state::BasicCoevolutionaryState, 
)
    new_species = [
        create_species(
            species_creators[index],
            state.random_number_generator, 
            state.individual_id_counter,
            state.gene_id_counter,
            state.species[index],
            state.evaluations[index]
        ) for (index) in eachindex(species_creators)
    ]

    return new_species
end
