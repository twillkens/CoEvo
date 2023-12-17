export BasicCoevolutionaryState, BasicCoevolutionaryStateCreator, create_species

using Base: @kwdef
using ...Jobs: JobCreator
using ...Performers: Performer
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...Modes: ModesSpeciesCreator

import ...Abstract.States: get_interactions, get_n_workers, get_phenotype_creators

@kwdef struct BasicCoevolutionaryState <: State
    id::String
    rng::AbstractRNG
    trial::Int
    generation::Int  # Generation number
    species_creators::Vector{<:SpeciesCreator}  # Species creators
    job_creator::JobCreator  # Job creator
    performer::Performer  # Performer
    last_reproduction_time::Float64  # Time spent on reproduction in the last generation
    evaluation_time::Float64  # Time spent on evaluation in the last generation
    individual_id_counter::Counter  # Counter for generating unique individual IDs
    gene_id_counter::Counter  # Counter for generating unique gene IDs
    all_species::Vector{<:AbstractSpecies}  # Species in the ecosystem
    individual_outcomes::Dict{Int, Dict{Int, Float64}}  # Processed outcomes for each individual
    evaluations::Vector{<:Evaluation}  # Species evaluations based on the results
    observations::Vector{<:Observation}  # Extracted observations from results
end

get_interactions(state::BasicCoevolutionaryState) = state.job_creator.interactions
get_n_workers(state::BasicCoevolutionaryState) = state.performer.n_workers
get_phenotype_creators(state::BasicCoevolutionaryState) = [
    species_creator.phenotype_creator for species_creator in state.species_creators
]

@kwdef struct BasicCoevolutionaryStateCreator <: StateCreator end

function create_species(
    species_creators::Vector{<:SpeciesCreator}, state::BasicCoevolutionaryState, 
)
    new_species = [
        create_species(
            species_creators[index],
            state.rng, 
            state.individual_id_counter,
            state.gene_id_counter,
            state.all_species[index],
            state.evaluations[index]
        ) for (index) in eachindex(species_creators)
    ]

    return new_species
end

function create_species(
    species_creators::Vector{<:ModesSpeciesCreator}, state::BasicCoevolutionaryState, 
)
    new_species = [
        create_species(species_creators[index], state.all_species[index], state) 
        for (index) in eachindex(species_creators)
    ]

    return new_species
end
