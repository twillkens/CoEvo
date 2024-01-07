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

function evolve!(state::ModesEcosystemState)
    for _ in 1:state.configuration.n_generations
        next_generation!(state)
        if state.generation % 25 == 0
            GC.gc()
        end
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
    ecosystem_channels = [RemoteChannel(()->Channel{ModesEcosystemState}(1)) for _ in 1:config.n_ecosystems]
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
        generation =0,
        reproduction_time = 0.0,
        simulation_time = 0.0,
        evaluation_time = 0.0,
        rng = rng,
        ecosystem_channels = ecosystem_channels,
        #archivers,
    )
    return state
end

function evolve!(state::IslandModelState)
    for _ in 1:state.configuration.n_generations
        futures = []
        for channel in state.ecosystem_channels
            # Determine the worker ID where the ModesEcosystemState resides
            worker_id = channel.where
            # Run next_generation! on the worker process, updating the state in-place
            future = @spawnat worker_id begin
                modes_state = take!(channel)
                evolve!(modes_state)
                put!(channel, modes_state)
            end
            push!(futures, future)
        end

        # Wait for all processes to complete their task
        for future in futures
            fetch(future)
        end

        # Implement any operations needed after each generation
        # Note: These operations should avoid moving the whole state from the workers
    end
end



end