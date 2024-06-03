module IslandModel

export ModesEcosystemState, IslandModelState, next_generation!, evolve!
export ContinuousPredictionGameExperimentConfiguration


include("imports.jl")

include("config.jl")

include("topologies.jl")

include("simulation.jl")

include("function_graphs.jl")

include("reproducer.jl")

include("evaluation.jl")

abstract type Configuration end

using Base: @kwdef

using ....Abstract
using ...Archivers.Globals
using ...Archivers.GenotypeSize


using ...Ecosystems: create_ecosystem

ModesEcosystemState(config::PredictionGameConfiguration) = ModesEcosystemState(config, 1, config.seed)



using ...Jobs
using ...Performers


function retrieve_migrants(state::ModesEcosystemState)
    I = typeof(first(first(state.ecosystem.species).population))
    migrant_dict = Dict{String, Vector{I}}()
    for (species, evaluation) in zip(state.ecosystem.species, state.evaluations)
        migrant_ids = Set([record.id for record in evaluation.records[1:state.configuration.n_migrate]])
        migrants = [individual for individual in species.population if individual.id in migrant_ids]
        println("migrants_retrieve_$(species.id): ", [individual.id for individual in migrants])
        migrant_dict[species.id] = migrants
    end
    return migrant_dict
end

#function accept_migrants!(state::ModesEcosystemState, migrant_dict::Dict{String, Vector{<:Individual}})
function accept_migrants!(state::ModesEcosystemState, migrant_dict::Dict)
    println("accept_migrants!")
    for (species, evaluation) in zip(state.ecosystem.species, state.evaluations)
        species_migrants = migrant_dict[species.id]
        println("migrants_accept_$(species.id): ", [individual.id for individual in species_migrants])
        reversed_record_ids = [record.id for record in reverse(evaluation.records)]
        to_replace_ids = Set(reversed_record_ids[1:state.configuration.n_migrate])
        filter!(individual -> individual.id ∉ to_replace_ids, species.population)
        append!(species.population, species_migrants)
    end
end

using Distributed
using ...Individuals

Base.@kwdef mutable struct IslandModelState{
    #C <: Configuration, I <: Individual, G <: Genotype, S <: State, T
    C, T
} <: State
    configuration::C
    generation::Int
    reproduction_time::Float64
    simulation_time::Float64
    evaluation_time::Float64
    rng::AbstractRNG
    ecosystem_channels::Vector{T}
    #current_modes_pruned::Vector{I}
    #previous_modes_pruned::Vector{I}
    #all_previous_modes_pruned::Set{G}
    #archivers::Vector{<:Archiver}
end

function IslandModelState(config::PredictionGameConfiguration)
    rng = StableRNG(config.seed)
    ecosystem_seeds = [abs(rand(rng, Int)) for _ in 1:config.n_ecosystems]
    ecosystem_channels = [RemoteChannel(()->Channel{ModesEcosystemState}(1), i + 1) for i in 1:config.n_ecosystems]
        for (i, seed) in enumerate(ecosystem_seeds)
        @spawnat i+1 begin
            state = ModesEcosystemState(config, i, seed)
            put!(ecosystem_channels[i], state)
        end
    end

    #ecosystem_channels = [RemoteChannel(()->Channel{EcosystemState}(1)) for _ in 1:config.n_ecosystems]
    #archivers = [EcosystemArchiver(config.archive_interval, get_archive_directory(config)) for _ in 1:config.n_ecosystems]
    state = IslandModelState(
        configuration = config,
        generation = 0,
        reproduction_time = 0.0,
        simulation_time = 0.0,
        evaluation_time = 0.0,
        rng = rng,
        ecosystem_channels = ecosystem_channels,
        #archivers,
    )
    return state
end

function get_nsew(trial::Int, n_x::Int, n_y::Int)
    # Calculate the row and column of the trial
    row, col = divrem(trial - 1, n_x) .+ 1

    # Calculate the neighbors with toroidal wrapping
    north = ((row - 2 + n_y) % n_y) * n_x + col
    south = (row % n_y) * n_x + col
    east = (row - 1) * n_x + (col % n_x) + 1
    west = (row - 1) * n_x + ((col - 2 + n_x) % n_x) + 1

    return [north, south, east, west]
end


function even_grid(n::Int)
    # Check if n is a perfect square
    if isqrt(n)^2 == n
        return (isqrt(n), isqrt(n))
    end

    # Find factors of n that are as close as possible to each other
    for i in reverse(1:isqrt(n))
        if n % i == 0
            return (i, n ÷ i)
        end
    end

    # If no suitable factors found, throw an error
    throw(ArgumentError("Cannot create an even grid with $n elements"))
end

function merge_dicts(dicts::Vector{Dict{T, Vector{U}}}) where {T, U}
    merged = Dict{T, Vector{U}}()

    # Iterate over all dictionaries
    for d in dicts
        # Iterate over each key-value pair in the dictionary
        for (key, value) in d
            # If the key already exists in the merged dictionary, append the values
            if haskey(merged, key)
                append!(merged[key], value)
            else
                # Otherwise, create a new entry with the key and its values
                merged[key] = value
            end
        end
    end

    return merged
end



function evolve!(state::IslandModelState)
    for _ in 1:100
        futures = []
        for channel in state.ecosystem_channels
            # Determine the worker ID where the ModesEcosystemState resides
            worker_id = channel.where
            # Run next_generation! on the worker process, updating the state in-place
            future = @spawnat worker_id begin
                modes_state = take!(channel)
                evolve!(modes_state, 100)
                put!(channel, modes_state)
            end
            push!(futures, future)
        end

        # Wait for all processes to complete their task
        [fetch(future) for future in futures]

                # Step 2: Retrieve migrants from each ecosystem
        migrant_dicts = []
        for channel in state.ecosystem_channels
            future = @spawnat channel.where begin
                modes_state = take!(channel)
                migrants = retrieve_migrants(modes_state)
                put!(channel, modes_state)
                return migrants
            end
            push!(migrant_dicts, future)
        end
        migrant_dicts = [fetch(future) for future in migrant_dicts]

        # Step 4: Integrate migrants into each ecosystem
        futures = []
        for (i, channel,) in enumerate(state.ecosystem_channels,)
            nsew = get_nsew(i, even_grid(state.configuration.n_ecosystems)...)
            migrants = merge_dicts([migrant_dicts[j] for j in nsew])

            future = @spawnat channel.where begin
                modes_state = take!(channel)
                accept_migrants!(modes_state, migrants)
                put!(channel, modes_state)
            end
            push!(futures, future)
        end

        [fetch(future) for future in futures]

    end
end



end