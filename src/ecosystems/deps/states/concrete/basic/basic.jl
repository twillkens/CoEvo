module Basic

export BasicCoevolutionaryState, BasicCoevolutionaryStateCreator

using Random: AbstractRNG
using DataStructures: SortedDict
using ...States.Abstract: CoevolutionaryState, CoevolutionaryStateCreator
using ....Ecosystems.Utilities.Counters: Counter
using ....Ecosystems.Species.Abstract: AbstractSpecies
using ....Ecosystems.Species.Evaluators.Abstract: Evaluation
using ....Ecosystems.Interactions.Observers.Abstract: Observation
using Base: @kwdef

@kwdef struct BasicCoevolutionaryState <: CoevolutionaryState
    id::String
    rng::AbstractRNG
    trial::Int
    generation::Int  # Generation number
    indiv_id_counter::Counter  # Counter for generating unique individual IDs
    gene_id_counter::Counter  # Counter for generating unique gene IDs
    species::Vector{<:AbstractSpecies}  # Species in the ecosystem
    individual_outcomes::Dict{Int, SortedDict{Int, Float64}}  # Processed outcomes for each individual
    evaluations::Vector{<:Evaluation}  # Species evaluations based on the results
    observations::Vector{<:Observation}  # Extracted observations from results
end

@kwdef struct BasicCoevolutionaryStateCreator <: CoevolutionaryStateCreator end

end