module Evolutionary

export EvolutionaryState, create_state, evolve, evolve!, increment_generation
export load_state_from_checkpoint

import ...Archivers: archive!
import ...Abstract.States: get_n_generations, get_rng
import ...Abstract.States: get_individual_id_counter, get_gene_id_counter
import ...Abstract.States: get_reproduction_time, get_simulation_time, get_evaluation_time
import ...Abstract.States: get_generation, get_n_generations, get_all_species
import ...Ecosystems: create_ecosystem

import ...Jobs: create_jobs
import ...Abstract.States: get_all_species, get_phenotype_creators, get_evaluators, get_interactions
import ...Abstract.States: get_n_workers, get_rng_state_after_creation

using Random: AbstractRNG
using ...Counters: Counter
using ...Abstract.States: State
using ...NewConfigurations: Configuration
using ...Ecosystems: EcosystemCreator, Ecosystem
using ...Jobs: JobCreator
using ...Performers: Performer
using ...Results: Result
using ...Evaluators: Evaluation
using ...Archivers: Archiver
using ...States.Global: GlobalState
using ...Results: get_individual_outcomes
using ...Evaluators: evaluate
using ...States.Global: GlobalState
using ...NewConfigurations.ExperimentConfigurations: ExperimentConfiguration
using ...NewConfigurations.ExperimentConfigurations.PredictionGame: get_archive_path, get_root_directory

using ...NewConfigurations.ExperimentConfigurations.PredictionGame: PredictionGame as PredictionGameConfig
using .PredictionGameConfig: PredictionGameExperimentConfiguration
using .PredictionGameConfig: make_ecosystem_creator, make_performer, make_archivers, make_job_creator
using ...Ecosystems.Null: NullEcosystem
using ...Results.Null: NullResult
using ...Evaluators.Null: NullEvaluation
using ...Performers: perform

struct EvolutionaryState{
    C <: Configuration,
    S <: State,
    E1 <: EcosystemCreator, 
    E2 <: Ecosystem, 
    J <: JobCreator,
    P <: Performer,
    R <: Result, 
    E3 <: Evaluation,
    A <: Archiver,
} <: State 
    configuration::C
    global_state::S
    ecosystem_creator::E1
    ecosystem::E2
    job_creator::J
    performer::P
    results::Vector{R}
    evaluations::Vector{E3}
    archivers::Vector{A}
end

# Global state getters
get_generation(state::EvolutionaryState) = get_generation(state.global_state)
get_rng(state::EvolutionaryState) = get_rng(state.global_state)
get_individual_id_counter(
    state::EvolutionaryState
) = get_individual_id_counter(state.global_state)
get_gene_id_counter(state::EvolutionaryState) = get_gene_id_counter(state.global_state)
get_reproduction_time(state::EvolutionaryState) = get_reproduction_time(state.global_state)
get_simulation_time(state::EvolutionaryState) = get_simulation_time(state.global_state)
get_evaluation_time(state::EvolutionaryState) = get_evaluation_time(state.global_state)

# Ecosystem creator getters
get_evaluators(state::EvolutionaryState) = get_evaluators(state.ecosystem_creator)
get_phenotype_creators(state::EvolutionaryState) = get_phenotype_creators(state.ecosystem_creator)

get_n_generations(state::EvolutionaryState) = get_n_generations(state.configuration)
get_all_species(state::EvolutionaryState) = state.ecosystem.species
get_n_workers(state::EvolutionaryState) = get_n_workers(state.configuration)
get_interactions(state::EvolutionaryState) = state.job_creator.interactions
get_rng_state_after_creation(state::EvolutionaryState) = state.global_state.rng_state_after_creation



function create_ecosystem(state::EvolutionaryState)
    reproduction_time_start = time()
    new_ecosystem = create_ecosystem(state.ecosystem_creator, state.ecosystem, state)
    reproduction_time = time() - reproduction_time_start
    return new_ecosystem, reproduction_time
end

function create_jobs(ecosystem::Ecosystem, state::State)
    jobs = create_jobs(
        state.job_creator,
        get_rng(state),
        get_all_species(ecosystem),
        get_phenotype_creators(state),
    )
    return jobs
end


function perform_simulation(state::EvolutionaryState)
    simulation_time_start = time()
    ecosystem = state.ecosystem
    jobs = create_jobs(ecosystem, state)
    results = perform(state.performer, jobs)
    simulation_time = time() - simulation_time_start
    return results, simulation_time
end


function perform_evaluation(ecosystem::Ecosystem, results::Vector{<:Result}, state::EvolutionaryState)
    evaluation_time_start = time()
    evaluations = evaluate(
        get_evaluators(state), 
        get_rng(state), 
        get_all_species(ecosystem), 
        get_individual_outcomes(results), 
    )
    evaluation_time = time() - evaluation_time_start
    return evaluations, evaluation_time
end

function EvolutionaryState(
    global_state::GlobalState,
    ecosystem::Ecosystem,
    results::Vector{<:Result},
    evaluations::Vector{<:Evaluation},
    state::State
)
    state = EvolutionaryState(
        state.configuration,
        global_state,
        state.ecosystem_creator,
        ecosystem,
        state.job_creator,
        state.performer,
        results,
        evaluations,
        state.archivers,
    )
    return state
end

function add_rng_state_after_creation(global_state::GlobalState, state::State)
    rng_state_after_creation = string(get_rng(state).state)
    state = GlobalState(
        global_state.generation,
        global_state.rng,
        rng_state_after_creation,
        global_state.individual_id_counter,
        global_state.gene_id_counter,
        global_state.reproduction_time,
        global_state.simulation_time,
        global_state.evaluation_time,
    )
    return state
end

function EvolutionaryState(ecosystem::Ecosystem, state::State)
    global_state = add_rng_state_after_creation(state.global_state, state)
    state = EvolutionaryState(
        state.configuration, global_state, state.ecosystem_creator,
        ecosystem, state.job_creator, state.performer,
        NullResult[], NullEvaluation[], state.archivers,
    )
    return state
end

function EvolutionaryState(results::Vector{<:Result}, state::State)
    state = EvolutionaryState(
        state.configuration, state.global_state, state.ecosystem_creator,
        state.ecosystem, state.job_creator, state.performer,
        results, NullEvaluation[], state.archivers,
    )
    return state
end

function EvolutionaryState(evaluations::Vector{<:Evaluation}, state::State)
    state = EvolutionaryState(
        state.configuration, state.global_state, state.ecosystem_creator,
        state.ecosystem, state.job_creator, state.performer,
        state.results, evaluations, state.archivers,
    )
    return state
end

function EvolutionaryState(global_state::GlobalState, state::State)
    state = EvolutionaryState(
        state.configuration, global_state, state.ecosystem_creator,
        state.ecosystem, state.job_creator, state.performer,
        state.results, state.evaluations, state.archivers,
    )
    return state
end

function increment_generation(state::EvolutionaryState)
    global_state = GlobalState(
        get_generation(state) + 1,
        get_rng(state),
        "",
        get_individual_id_counter(state),
        get_gene_id_counter(state),
        0.0,
        0.0,
        0.0
    )
    state = EvolutionaryState(global_state, state)
    return state
end

function create_state(state::EvolutionaryState)
    state = increment_generation(state)
    println("----$(get_generation(state))-------")
    ecosystem, reproduction_time = create_ecosystem(state)
    state = EvolutionaryState(ecosystem, state)
    #println("RNG_state_after_create = $(get_rng(state).state)")
    results, simulation_time = perform_simulation(state)
    state = EvolutionaryState(results, state)
    #println("RNG_state_after_perform = $(get_rng(state).state)")
    evaluations, evaluation_time = perform_evaluation(ecosystem, results, state)
    state = EvolutionaryState(evaluations, state)
    #println("RNG_state_after_evaluate = $(get_rng(state).state)")
    global_state = GlobalState(simulation_time, reproduction_time, evaluation_time, state)
    state = EvolutionaryState(global_state, state)
    return state
end

function archive!(state::EvolutionaryState)
    for archiver in state.archivers
        archive!(archiver, state)
    end
end

function evolve!(state::EvolutionaryState)
    while get_generation(state) < get_n_generations(state)
        state = create_state(state)
        archive!(state)
        #if get_generation(state) == 50
        #    return state
        #end
    end
    return state
end

function evolve(state::EvolutionaryState)
    while get_generation(state) < get_n_generations(state)
        #if get_generation(state) == 51
        #    return state
        #end
        #println("Generation: ", get_generation(state))
        state = create_state(state)
    end
    return state
end

function EvolutionaryState(config::PredictionGameExperimentConfiguration)
    state = EvolutionaryState(
        config,
        GlobalState(config.globals),
        make_ecosystem_creator(config),
        NullEcosystem(), 
        make_job_creator(config),
        make_performer(config), 
        NullResult[], 
        NullEvaluation[], 
        make_archivers(config), 
    )
    return state
end

using HDF5: h5open, File

using ...States.Global: load_most_recent_global_state
using ...NewConfigurations.ExperimentConfigurations.PredictionGame: load_prediction_game_experiment, get_archive_path
using ...NewConfigurations.ExperimentConfigurations.PredictionGame: get_archive_path
using ...NewConfigurations.ExperimentConfigurations.PredictionGame: load_most_recent_ecosystem


function load_state_from_checkpoint(file::File)
    config = load_prediction_game_experiment(file)
    ecosystem = load_most_recent_ecosystem(file)
    global_state = load_most_recent_global_state(file)
    state = EvolutionaryState(
        config,
        global_state,
        make_ecosystem_creator(config),
        ecosystem, 
        make_job_creator(config),
        make_performer(config), 
        NullResult[], 
        NullEvaluation[], 
        make_archivers(config), 
    )
    results, simulation_time = perform_simulation(state)
    state = EvolutionaryState(results, state)
    #println("RNG_state_after_perform = $(get_rng(state).state)")
    evaluations, evaluation_time = perform_evaluation(ecosystem, results, state)
    state = EvolutionaryState(evaluations, state)
    #println("RNG_state_after_evaluate = $(get_rng(state).state)")
    global_state = GlobalState(
        simulation_time, get_reproduction_time(state), evaluation_time, state
    )
    state = EvolutionaryState(global_state, state)
    return state
end


function evolve!(config::PredictionGameExperimentConfiguration)
    archive_path = get_archive_path(config)
    if !isfile(archive_path)
        println("Creating new archive at $archive_path")
        mkpath(get_root_directory(config))
        file = h5open(archive_path, "w")
        archive!(file, config, "configuration")
        close(file)
        state = EvolutionaryState(config)
    else 
        println("Loading archive from $archive_path")
        file = h5open(archive_path, "r")
        state = load_state_from_checkpoint(file)
        close(file)
    end
    state = evolve!(state)
    return state
end

end
