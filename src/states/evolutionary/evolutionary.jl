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
import ...Abstract.States: get_n_workers, get_rng_state_after_creation, get_trial

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
get_trial(state::EvolutionaryState) = state.configuration.globals.trial



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

using ...Species: get_population
function perform_simulation(state::EvolutionaryState)
    simulation_time_start = time()
    ecosystem = state.ecosystem
    jobs = create_jobs(ecosystem, state)
    results = perform(state.performer, jobs)
    #if get_generation(state) == 20
    #    for species in ecosystem.species
    #        for individual in get_population(species)
    #            id = individual.id
    #            genotype = individual.genotype
    #            println("genotype_$id = ", genotype)
    #        end
    #    end
    #    for phenotype in values(first(jobs).phenotypes)
    #        id = phenotype.id
    #        println("phenotype_$id = ", phenotype)
    #    end
    #    println("individual_outcomes = ", get_individual_outcomes(results))
    #end
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
    #println("\n----Generation: $(get_generation(state))-------")
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
    if get_generation(state) % 25 == 0
        GC.gc()
    end
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

using ...NewConfigurations.ExperimentConfigurations.PredictionGame: load_prediction_game_experiment 
using ...NewConfigurations.ExperimentConfigurations.PredictionGame: get_archive_directory
using ...NewConfigurations.ExperimentConfigurations.PredictionGame: load_ecosystem

function get_most_recent_generation(file::File)
    generations = [parse(Int, key) for key in keys(file["generations"])]
    gen = maximum(generations)
    return gen
end

using HDF5: delete_object

export load_state_from_checkpoint, find_recent_valid_checkpoint, initialize_new_archive
using ...States.Global: load_global_state

function load_state_from_checkpoint(config::PredictionGameExperimentConfiguration, file::File)
    global_state = load_global_state(file)
    ecosystem = load_ecosystem(config, global_state.generation, file)
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
    #println("RNG_state_after_create = $(get_rng(state).state)")
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
    #println("Loaded state at generation $(get_generation(state))")
    return state
end

function load_state_from_checkpoint(
    config::PredictionGameExperimentConfiguration, file_path::String
)
    file = h5open(file_path, "r+")
    state = load_state_from_checkpoint(config, file)
    close(file)
    return state
end

function initialize_new_archive(config::PredictionGameExperimentConfiguration)
    archive_directory = get_archive_directory(config)
    println("Creating new archive directory at $archive_directory")
    mkpath(archive_directory)
    config_file = h5open("$archive_directory/configuration.h5", "w")
    archive!(config_file, config, "configuration")
    close(config_file)
    return EvolutionaryState(config)
end

function find_recent_valid_checkpoint(archive_directory::String)
    generations_directory = joinpath(archive_directory, "generations")
    checkpoint_files = filter(x -> occursin(r"\.h5$", x), readdir(generations_directory))
    sort!(checkpoint_files, by = x -> parse(Int, match(r"(\d+)\.h5$", x).captures[1]), rev = true)
    
    for chk_file in checkpoint_files
        file_path = joinpath(generations_directory, chk_file)  # Corrected the path
        file = nothing  # Initialize `file` to nothing
        try
            file = h5open(file_path, "r")
            if "valid" in keys(file)
                println("Valid checkpoint found: $file_path")
                return file_path  # Return the path of the valid checkpoint
            else
                println("Invalid checkpoint, deleting: $file_path")
                rm(file_path; force=true)
            end
        catch e
            println("Error reading checkpoint $file_path: $e")
            # Optionally delete the corrupted file
            if isfile(file_path)
                rm(file_path; force=true)
            end
        finally
            # Safely attempt to close the file if it was opened
            if file !== nothing
                close(file)
            end
        end
    end
    return nothing  # Return nothing if no valid checkpoints are found
end



function evolve!(config::PredictionGameExperimentConfiguration)
    archive_directory = get_archive_directory(config)

    if !isdir(archive_directory)
        state = initialize_new_archive(config)
    else
        println("Loading archive from $archive_directory")
        println("config = $config")
        config_path = "$archive_directory/configuration.h5"
        config = load_prediction_game_experiment(config_path)

        checkpoint_path = find_recent_valid_checkpoint(archive_directory)
        
        if checkpoint_path !== nothing
            state = load_state_from_checkpoint(config, checkpoint_path)
        else
            println("No valid checkpoints found. Starting from initial state.")
            state = EvolutionaryState(config)
        end
    end

    flush(stdout)
    state = evolve!(state)
    return state
end


#function evolve!(config::PredictionGameExperimentConfiguration)
#    archive_directory = get_archive_directory(config)
#    if !isdir(archive_directory)
#        println("Creating new archive directory at $archive_directory")
#        mkpath(archive_directory)
#        config_file = h5open("$archive_directory/config.h5", "w")
#        archive!(config_file, config, "configuration")
#        close(config_file)
#        state = EvolutionaryState(config)
#    else 
#        println("Loading archive from $archive_path")
#        println("config = $config")
#        # change this so that we scan the archive directory for the most recent checkpoint
#        # each generation archive is numbered e.g., 1.h5, 50.h5, 100.h5, etc.
#        # we try to open the checkpoint. If it is corrupted or if it does not contain 
#        # the "valid" key, we delete it and try the next most recent checkpoint
#        #file = h5open(archive_path, "r+")
#        file = nothing
#        state = load_state_from_checkpoint(file)
#        close(file)
#    end
#    flush(stdout)
#    state = evolve!(state)
#    return state
#end

end
