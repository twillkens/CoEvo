module Basic

export BasicEvolutionaryState, evolve!, PrimerState

import ....Interfaces: update_ecosystem!, create_ecosystem, archive!
using ....Abstract
using ....Interfaces
using StableRNGs: StableRNG

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
    reproducer::R1
    reproduction_time::Float64
    simulator::S
    simulation_time::Float64
    evaluator::E1
    evaluation_time::Float64
    ecosystem::E2
    results::Vector{R2}
    evaluations::Vector{E3}
    archivers::Vector{A}
end

const simulator_properties = Set([:interactions, :matchmaker, :job_creator, :performer])

const reproducer_properties = Set([
    :species_ids, :gene_id_counter, :genotype_creator, :recombiner, :mutator, 
    :phenotype_creator, :individual_id_counter, :individual_creator, :selector, 
    :species_creator, :ecosystem_creator
])


function Base.getproperty(state::BasicEvolutionaryState, property::Symbol) 
    if property in simulator_properties
        return getproperty(state.reproducer, property)
    elseif property in reproducer_properties
        return getproperty(state.simulator, property)
    else
        return getfield(state, property)
    end
end


function update_ecosystem!(state::BasicEvolutionaryState)
    reproduction_time_start = time()
    update_ecosystem!(state.ecosystem, state.ecosystem_creator, state)
    reproduction_time = time() - reproduction_time_start
    state.reproduction_time = round(reproduction_time; digits = 3)
end

function perform_simulation(
    ecosystem::Ecosystem, job_creator::JobCreator, performer::Performer, state::State
)
    simulation_time_start = time()
    jobs = create_jobs(job_creator, ecosystem, state)
    results = perform(performer, jobs)
    simulation_time = round(time() - simulation_time_start; digits = 3)
    return results, simulation_time
end

function perform_simulation!(state::BasicEvolutionaryState)
    new_results, simulation_time = perform_simulation(
        state.ecosystem, state.job_creator, state.performer, state
    )
    empty!(state.results)
    append!(state.results, new_results)
    state.simulation_time = simulation_time
end

function perform_evaluation(
    ecosystem::Ecosystem, evaluator::Evaluator, results::Vector{<:Result}, state::State
)
    evaluation_time_start = time()
    evaluations = evaluate(evaluator, ecosystem, results, state)
    evaluation_time = round(time() - evaluation_time_start; digits = 3)
    return evaluations, evaluation_time
end

function perform_evaluation!(state::BasicEvolutionaryState)
    evaluations, evaluation_time = perform_evaluation(
        state.ecosystem, state.evaluator, state.results, state
    )
    state.evaluation_time = evaluation_time
    empty!(state.evaluations)
    append!(state.evaluations, evaluations)
end

function archive!(state::BasicEvolutionaryState)
    for archiver in state.archivers
        archive!(archiver, state)
    end
end

function next_generation!(state::BasicEvolutionaryState)
    state.generation += 1
    update_ecosystem!(state)
    perform_simulation!(state)
    perform_evaluation!(state)
    archive!(state)
end

function evolve!(state::BasicEvolutionaryState, n_generations::Int)
    println("received evolution command")
    for _ in 1:n_generations
        next_generation!(state)
        if state.generation % 25 == 0
            GC.gc()
        end
    end
end

function evolve!(state::BasicEvolutionaryState) 
    evolve!(state, state.configuration.n_generations)
end

#evolve!(state::ModesEcosystemState) = evolve!(state, state.configuration.n_generations)

Base.@kwdef struct PrimerState{
    C <: Configuration, R <: Reproducer, S <: Simulator, E <: Evaluator
} <: State
    rng::AbstractRNG
    id::Int
    configuration::C
    n_population::Int
    reproducer::R
    simulator::S
    evaluator::E
end

function Base.getproperty(state::PrimerState, property::Symbol)
    if property in reproducer_properties
        return getproperty(state.reproducer, property)
    elseif property in simulator_properties
        return getproperty(state.simulator, property)
    else
        return getfield(state, property)
    end
end

function create_ecosystem(state::PrimerState,)
    reproduction_time_start = time()
    ecosystem = create_ecosystem(state.ecosystem_creator, state.id, state)
    reproduction_time = round(time() - reproduction_time_start; digits = 3)
    return ecosystem, reproduction_time
end

function BasicEvolutionaryState(
    config::Configuration, id::Int, seed::Int
)
    rng = StableRNG(seed)
    reproducer = create_reproducer(config)
    simulator = create_simulator(config)
    evaluator = create_evaluator(config)
    archivers = create_archivers(config)
    primer_state = PrimerState(
        rng = rng, 
        id = id, 
        configuration = config, 
        n_population = reproducer.species_creator.n_population, 
        reproducer = reproducer,
        simulator = simulator,
        evaluator = evaluator
    )
    ecosystem, reproduction_time = create_ecosystem(primer_state)
    results, simulation_time = perform_simulation(
        ecosystem, simulator.job_creator, simulator.performer, primer_state
    )
    evaluations, evaluation_time = perform_evaluation(
        ecosystem, evaluator, results, primer_state
    )

    state = BasicEvolutionaryState(
        id = id,
        configuration = config,
        generation = 1,
        rng = rng,
        reproducer = reproducer,
        reproduction_time = reproduction_time,
        simulator = simulator,
        simulation_time = simulation_time,
        evaluator = evaluator,
        evaluation_time = evaluation_time,
        ecosystem = ecosystem,
        results = results,
        evaluations = evaluations,
        archivers = archivers
    )
    return state
end

end