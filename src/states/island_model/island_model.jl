module IslandModel

export ModesEcosystemState, IslandModelState, next_generation!, evolve!, PredictionGameConfiguration


include("imports.jl")

include("config.jl")

include("topologies.jl")

include("job_creator.jl")

include("function_graphs.jl")

include("ecosystem_creator.jl")

abstract type Configuration end

using ...Results
using ...Results: get_individual_outcomes
using ...Individuals


Base.@kwdef mutable struct ModesEcosystemState{
    EC <: EcosystemCreator,
    J <: JobCreator,
    P <: Performer,
} <: State
    configuration::PredictionGameConfiguration
    generation::Int
    rng::AbstractRNG
    reproduction_time::Float64
    simulation_time::Float64
    evaluation_time::Float64
    individual_id_counter::StepCounter
    gene_id_counter::StepCounter
    ecosystem_creator::EC
    ecosystem::Ecosystem
    previous_modes_checkpoint_ecosystem::Ecosystem
    job_creator::J
    performer::P
    results::Vector{Result}
    evaluations::Vector{Evaluation}
    archivers::Vector{Archiver}
end

using ...Archivers
using ...Results.Null
using ...Archivers.Globals
using ...Archivers.GenotypeSize

function ModesEcosystemState(config::PredictionGameConfiguration, id::Int, seed::Int)
    state = ModesEcosystemState(
        configuration = config,
        generation = 0,
        rng = StableRNG(seed),
        reproduction_time = 0.0,
        simulation_time = 0.0,
        evaluation_time = 0.0,
        individual_id_counter = StepCounter(id, config.n_ecosystems),
        gene_id_counter = StepCounter(id, config.n_ecosystems),
        ecosystem_creator = make_ecosystem_creator(config, id),
        ecosystem = NullEcosystem(),
        previous_modes_checkpoint_ecosystem = NullEcosystem(),
        job_creator = make_job_creator(config),
        performer = CachePerformer(n_workers = config.n_workers_per_ecosystem),
        results = Result[],
        evaluations = Evaluation[],
        archivers = Archiver[GlobalStateArchiver(), GenotypeSizeArchiver()]
    )
    return state
end

using ...Ecosystems: create_ecosystem

ModesEcosystemState(config::PredictionGameConfiguration) = ModesEcosystemState(config, 1, config.seed)

function create_ecosystem!(state::ModesEcosystemState)
    reproduction_time_start = time()
    state.ecosystem = create_ecosystem(state.ecosystem_creator, state.ecosystem, state)
    if state.generation == 1
        state.previous_modes_checkpoint_ecosystem = state.ecosystem
    end
    reproduction_time = time() - reproduction_time_start
    state.reproduction_time = round(reproduction_time; digits = 3)
end


using ...Jobs
using ...Performers

function perform_simulation!(state::State)
    simulation_time_start = time()
    phenotype_creators = [
        species_creator.phenotype_creator 
        for species_creator in state.ecosystem_creator.species_creators
    ]
    jobs = create_jobs(
        state.job_creator,
        state.rng,
        state.ecosystem.species,
        phenotype_creators,
    )
    state.results = perform(state.performer, jobs)
    state.simulation_time = round(time() - simulation_time_start; digits = 3)
end
using ...Evaluators

function perform_evaluation!(state::State)
    evaluation_time_start = time()
    state.evaluations = evaluate(
        [species_creator.evaluator for species_creator in state.ecosystem_creator.species_creators],
        state.rng,
        state.ecosystem.species,
        get_individual_outcomes(state.results), 
    )
    state.evaluation_time = round(time() - evaluation_time_start; digits = 3)
end

using ...Archivers: archive!

function next_generation!(state::ModesEcosystemState)
    state.generation += 1
    create_ecosystem!(state)
    perform_simulation!(state)
    perform_evaluation!(state)
    [archive!(archiver, state) for archiver in state.archivers]
end

function evolve!(state::ModesEcosystemState, n_generations::Int)
    println("received evolution command")
    for _ in 1:n_generations
        next_generation!(state)
        if state.generation % 25 == 0
            GC.gc()
        end
    end
end

evolve!(state::ModesEcosystemState) = evolve!(state, state.configuration.n_generations)

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
        #println("migrant_dicts: ", migrant_dicts)

        # Step 3: Distribute migrants (this could be more sophisticated in a real implementation)
        # For simplicity, rotate the migrant_dicts
        # TODO: REPLACE rotated_migrant_dicts with logic using NSEW, merging the dictionaries as needed
        # rotated_migrant_dicts = circshift(migrant_dicts, 1)


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