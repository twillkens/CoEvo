module Basic

export BasicEvolutionaryState, Timers 

import ....Interfaces: update_ecosystem!, evolve!, create_ecosystem, archive!
using ....Abstract
using ....Interfaces
using ...States.Primer: PrimerState
using ...Ecosystems.Simple: SimpleEcosystem, SimpleEcosystemCreator
using StableRNGs: StableRNG

mutable struct Timers
    reproduction_time::Float64
    simulation_time::Float64
    evaluation_time::Float64
end

@kwdef mutable struct BasicEvolutionaryState{
    C1 <: Configuration,
    C2 <: Counter,
    E1 <: EcosystemCreator,
    E2 <: Ecosystem,
    R1 <: Reproducer,
    S <: Simulator,
    R2 <: Result,
    E3 <: Evaluator,
    E4 <: Evaluation,
    A <: Archiver
} <: State
    id::Int
    configuration::C1
    generation::Int
    rng::AbstractRNG
    rng_state_after_reproduction::String
    gene_id_counter::C2
    individual_id_counter::C2
    ecosystem_creator::E1
    ecosystem::E2
    reproducers::Vector{R1}
    simulator::S
    results::Vector{R2}
    evaluators::Vector{E3}
    evaluations::Vector{E4}
    archivers::Vector{A}
    timers::Timers
end

function update_ecosystem!(
    ecosystem::SimpleEcosystem, ::SimpleEcosystemCreator, state::BasicEvolutionaryState
)
    reproduction_time = update_ecosystem_with_time!(
        ecosystem, state.ecosystem_creator, state.evaluations, state.reproducers, state
    )
    state.rng_state_after_reproduction = string(state.rng.state)
    state.timers.reproduction_time = reproduction_time
end

function update_ecosystem!(state::BasicEvolutionaryState)
    update_ecosystem!(state.ecosystem, state.ecosystem_creator, state)
end

function perform_simulation!(state::BasicEvolutionaryState)
    empty!(state.results)
    new_results, simulation_time = simulate_with_time(
        state.simulator, state.ecosystem, state
    )
    append!(state.results, new_results)
    state.timers.simulation_time = simulation_time
end

function perform_evaluations!(state::BasicEvolutionaryState)
    empty!(state.evaluations)
    evaluations, evaluation_time = evaluate_with_time(
        state.ecosystem, state.evaluators, state.results, state
    )
    append!(state.evaluations, evaluations)
    state.timers.evaluation_time = evaluation_time
end

function archive!(state::BasicEvolutionaryState)
    for archiver in state.archivers
        archive!(archiver, state)
    end
end

function check_if_individuals_are_unique(state::State)
    all_species = state.ecosystem.all_species
    species_ids = [
        [individual.id for individual in species.population] for species in all_species
    ]
    all_ids = vcat(species_ids...)
    unique_ids = Set(all_ids)
    if length(all_ids) != length(unique_ids)
        error("individual ids are not unique")
    end
end


function next_generation!(state::BasicEvolutionaryState)
    println("------ Generation: ", state.generation, " ------")
    state.generation += 1
    println("\nUpdating ecosystem")
    update_ecosystem!(state)
    println("\nPerforming simulation")
    perform_simulation!(state)
    println("\nPerforming evaluations")
    perform_evaluations!(state)
    println("\nArchiving")
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
    ecosystem, reproduction_time = create_ecosystem_with_time(
        state.ecosystem_creator, state.reproducers, state
    )
    rng_state_after_reproduction = string(state.rng.state)
    results, simulation_time = simulate_with_time(state.simulator, ecosystem, state)
    evaluations, eval_time = evaluate_with_time(ecosystem, state.evaluators, results, state)
    archivers = create_archivers(config)
    timers = Timers(reproduction_time, simulation_time, eval_time)

    state = BasicEvolutionaryState(
        id = config.id,
        configuration = config,
        generation = 1,
        rng = state.rng,
        rng_state_after_reproduction = rng_state_after_reproduction,
        gene_id_counter = state.gene_id_counter,
        individual_id_counter = state.individual_id_counter,
        ecosystem_creator = state.ecosystem_creator,
        ecosystem = ecosystem,
        reproducers = state.reproducers,
        simulator = state.simulator,
        results = results,
        evaluators = state.evaluators,
        evaluations = evaluations,
        archivers = archivers,
        timers = timers
    )
    archive!(state)
    return state
end

end