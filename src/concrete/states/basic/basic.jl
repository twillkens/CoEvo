module Basic

export BasicEvolutionaryState, Timers 

import ....Interfaces: update_ecosystem!, evolve!, create_ecosystem, archive!
using StableRNGs: StableRNG
using ....Abstract
using ....Interfaces
using ...States.Primer: PrimerState

mutable struct Timers
    reproduction_time::Float64
    simulation_time::Float64
    evaluation_time::Float64
end

@kwdef mutable struct BasicEvolutionaryState{
    C <: Configuration,
    R1 <: Reproducer,
    S <: Simulator,
    E1 <: Evaluator,
    R2 <: Result,
    E2 <: Ecosystem,
    E3 <: Evaluation,
    A <: Archiver
} <: State
    id::Int
    configuration::C
    generation::Int
    rng::AbstractRNG
    rng_state_after_reproduction::String
    reproducer::R1
    simulator::S
    evaluator::E1
    ecosystem::E2
    results::Vector{R2}
    evaluations::Vector{E3}
    archivers::Vector{A}
    checkpoint_interval::Int
    timers::Timers
end

function update_ecosystem!(state::BasicEvolutionaryState)
    reproduction_time_start = time()
    update_ecosystem!(
        state.ecosystem, state.reproducer.ecosystem_creator, state.evaluations, state
    )
    state.rng_state_after_reproduction = string(state.rng.state)
    reproduction_time = time() - reproduction_time_start
    state.timers.reproduction_time = round(reproduction_time; digits = 3)
end

function perform_simulation!(state::BasicEvolutionaryState)
    new_results, simulation_time = simulate_with_time(
        state.simulator, state.ecosystem, state
    )
    empty!(state.results)
    append!(state.results, new_results)
    state.timers.simulation_time = simulation_time
end


function perform_evaluation!(state::BasicEvolutionaryState)
    evaluations, evaluation_time = evaluate_with_time(
        state.evaluator, state.ecosystem, state.results, state
    )
    state.timers.evaluation_time = evaluation_time
    empty!(state.evaluations)
    append!(state.evaluations, evaluations)
end

function archive!(state::BasicEvolutionaryState)
    using_archivers = state.checkpoint_interval > 0 
    is_checkpoint = using_archivers && state.generation % state.checkpoint_interval == 0
    if is_checkpoint
        for archiver in state.archivers
            archive!(archiver, state)
        end
    end
end

function check_if_individuals_are_unique(state::State)
    species_ids = [[individual.id for individual in species.population] for species in state.ecosystem.all_species]
    all_ids = vcat(species_ids...)
    unique_ids = Set(all_ids)
    if length(all_ids) != length(unique_ids)
        error("individual ids are not unique")
    end
end


function next_generation!(state::BasicEvolutionaryState)
    state.generation += 1
    update_ecosystem!(state)
    #println("----generation = $(state.generation)----")
    #println("rng_state_after_reproduction = $(state.rng.state)")
    perform_simulation!(state)
    #println("rng_state_after_simulation = $(state.rng.state)")
    perform_evaluation!(state)
    #println("rng_state_after_evaluation = $(state.rng.state)")
    archive!(state)
end

function evolve!(state::BasicEvolutionaryState, n_generations::Int)
    for _ in 1:n_generations
        next_generation!(state)
        if state.generation % 5 == 0
            GC.gc()
        end
    end
end

function evolve!(state::BasicEvolutionaryState) 
    while state.generation < state.configuration.n_generations
        next_generation!(state)
        if state.generation % 5 == 0
            GC.gc()
        end
    end
end

function BasicEvolutionaryState(config::Configuration)
    state = PrimerState(config)
    ecosystem, reproduction_time = create_ecosystem_with_time(state)
    #sort!(ecosystem.all_species, by = x -> x.id)
    rng_state_after_reproduction = string(state.rng.state)
    #println("rng_state_after_reproduction = $rng_state_after_reproduction")
    results, simulation_time = simulate_with_time(state.simulator, ecosystem, state)
    evaluations, evaluation_time = evaluate_with_time(state.evaluator, ecosystem, results, state)
    #println("rng_state_after_evaluation = $(state.rng.state)")
    archivers = create_archivers(config)
    timers = Timers(reproduction_time, simulation_time, evaluation_time)

    state = BasicEvolutionaryState(
        id = config.id,
        configuration = config,
        generation = 1,
        rng = state.rng,
        rng_state_after_reproduction = rng_state_after_reproduction,
        reproducer = state.reproducer,
        simulator = state.simulator,
        evaluator = state.evaluator,
        ecosystem = ecosystem,
        results = results,
        evaluations = evaluations,
        archivers = archivers,
        checkpoint_interval = config.checkpoint_interval,
        timers = timers
    )
    for archiver in state.archivers
        archive!(archiver, state)
    end
    return state
end

end