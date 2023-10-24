export BasicCoevolutionaryState, BasicCoevolutionaryStateCreator

@kwdef struct BasicCoevolutionaryState <: State
    id::String
    random_number_generator::AbstractRNG
    trial::Int
    generation::Int  # Generation number
    individual_id_counter::Counter  # Counter for generating unique individual IDs
    gene_id_counter::Counter  # Counter for generating unique gene IDs
    species::Vector{<:AbstractSpecies}  # Species in the ecosystem
    individual_outcomes::Dict{Int, SortedDict{Int, Float64}}  # Processed outcomes for each individual
    evaluations::Vector{<:Evaluation}  # Species evaluations based on the results
    observations::Vector{<:Observation}  # Extracted observations from results
end

@kwdef struct BasicCoevolutionaryStateCreator <: StateCreator end
