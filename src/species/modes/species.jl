export ModesCheckpointState, ModesSpecies

using ...Genotypes: Genotype

Base.@kwdef struct ModesCheckpointState{I <: ModesIndividual}
    population::Vector{I}
    pruned::Vector{I}
    pruned_fitnesses::Vector{Float64}
    elites::Vector{I}
end

function ModesCheckpointState(population::Vector{I}) where {I <: ModesIndividual}
    state = ModesCheckpointState{I}(
        population = copy(population),
        pruned = I[], 
        pruned_fitnesses = Float64[],
        elites = I[],
    )
    return state
end

#TODO: make a ModesEvolutionaryState that more elegantly handles the checkpointing and 
# measurements. We shouldn't have to pass around the previous state and the current state
# or keep the change/novelty values in the species struct.
Base.@kwdef struct ModesSpecies{S <: ModesCheckpointState, G <: Genotype} <: AbstractSpecies
    id::String
    current_state::S
    previous_state::S
    all_previous_pruned::Set{G}
    change::Int
    novelty::Int
end

function ModesSpecies(id::String, population::Vector{ModesIndividual{G}}) where {G <: Genotype}
    species = ModesSpecies(
        id = id, 
        current_state = ModesCheckpointState(population),
        previous_state = ModesCheckpointState(population),
        all_previous_pruned = Set{G}(),
        change = 0,
        novelty = 0,
    )
    return species
end