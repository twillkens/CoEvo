module Evolutionary

export EvolutionaryState

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
using ...Archivers: archive!
using ...States.Global: GlobalState
using ...NewConfigurations.ExperimentConfigurations: ExperimentConfiguration

using ...NewConfigurations.ExperimentConfigurations.PredictionGame: PredictionGame as PredictionGameConfig
using .PredictionGameConfig: PredictionGameExperimentConfiguration
using .PredictionGameConfig: make_ecosystem_creator, make_performer, make_archivers, make_job_creator
using ...Ecosystems.Null: NullEcosystem
import ...Abstract.States: get_n_generations
import ...Jobs: create_jobs
import ...Abstract.States: get_all_species, get_phenotype_creators
using ...Performers: perform



Base.@kwdef struct EvolutionaryState{
    C <: Configuration,
    E1 <: EcosystemCreator, 
    E2 <: Ecosystem, 
    J <: JobCreator,
    P <: Performer,
    R <: Result, 
    E3 <: Evaluation,
    A <: Archiver,
} <: State 
    configuration::C
    global_state::GlobalState
    ecosystem_creator::E1
    ecosystem::E2
    job_creator::JobCreator
    performer::Performer
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


import ...Ecosystems: create_ecosystem

function create_ecosystem(state::EvolutionaryState)
    reproduction_time_start = time()
    new_ecosystem = create_ecosystem(state.ecosystem_creator, state.ecosystem, state)
    reproduction_time = time() - reproduction_time_start
    return new_ecosystem, reproduction_time
end

function create_ecosystem(ecosystem_creator::EcosystemCreator, globals::GlobalState)
    reproduction_time_start = time()
    ecosystem = create_ecosystem(ecosystem_creator, globals)
    reproduction_time = time() - reproduction_time_start
    return ecosystem, reproduction_time
end

function create_jobs(state::State)
    jobs = create_jobs(
        state.job_creator,
        get_rng(state),
        get_all_species(state),
        get_phenotype_creators(state),
    )
    return jobs
end


function perform_simulation(state::EvolutionaryState)
    simulation_time_start = time()
    jobs = create_jobs(state)
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
        global_state,
        state.ecosystem_creator,
        ecosystem,
        results,
        evaluations,
        state.archivers,
    )
    return state
end

function evolve!(state::EvolutionaryState)
    while get_generation(state) < get_n_generations(state)
        ecosystem, reproduction_time = create_ecosystem(state)
        results, simulation_time = perform_simulation(state)
        evaluations, evaluation_time = perform_evaluation(ecosystem, results, state)
        global_state = GlobalState(simulation_time, reproduction_time, evaluation_time, state)
        state = EvolutionaryState(global_state, ecosystem, results, evaluations, state)
        archive!(state)
    end
    return state
end

function EvolutionaryState(config::PredictionGameExperimentConfiguration)
    
    state = EvolutionaryState(
        configuration = config,
        globals = GlobalState(config.globals),
        ecosystem_creator = make_ecosystem_creator(config),
        ecosystem = NullEcosystem(), 
        job_creator = make_job_creator(config),
        performer = make_performer(config), 
        Result[], 
        Evaluation[], 
        archivers = make_archivers(config), 
    )
    return state
end


end
