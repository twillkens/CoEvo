export ModesCheckpointState, ModesSpecies

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

#TODO: make it a set of genotypes for comparison savings
Base.@kwdef struct ModesSpecies{I <: ModesIndividual} <: AbstractSpecies
    id::String
    current_state::ModesCheckpointState{I}
    previous_state::ModesCheckpointState{I}
    all_previous_pruned::Set{I}
end

function ModesSpecies(id::String, population::Vector{I}) where {I <: ModesIndividual}
    species = ModesSpecies(
        id = id, 
        current_state = ModesCheckpointState(population),
        previous_state = ModesCheckpointState(population),
        all_previous_pruned = Set{I}(),
    )
    return species
end