module Basic

import ....Interfaces: update_ecosystem!, create_ecosystem, archive!
using ....Abstract
using ....Interfaces
using StableRNGs: StableRNG

@kwdef mutable struct BasicEvolutionaryState{
    C <: Configuration,
    R <: Reproducer,
    S <: Simulator,
    E1 <: Evaluator,
    E2 <: Ecosystem,
    I <: Individual,
    A <: Archiver
} <: State
    id::Int
    configuration::C
    generation::Int
    rng::AbstractRNG
    reproducer::R
    reproduction_time::Float64
    simulator::S
    simulation_time::Float64
    evaluator::E1
    evaluation_time::Float64
    ecosystem::E2
    results::Vector{R}
    evaluations::Vector{E2}
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
        return getproperty(state, property)
    end
end


function update_ecosystem!(state::BasicEvolutionaryState)
    reproduction_time_start = time()
    update_ecosystem!(state.ecosystem, state.ecosystem_creator, state)
    reproduction_time = time() - reproduction_time_start
    state.reproduction_time = round(reproduction_time; digits = 3)
end

function perform_simulation!(state::BasicEvolutionaryState)
    simulation_time_start = time()
    jobs = create_jobs(state.job_creator, state.ecosystem, state)
    empty!(state.results)
    new_results = perform(state.performer, jobs)
    append!(state.results, new_results)
    state.simulation_time = round(time() - simulation_time_start; digits = 3)
end

function perform_evaluation!(state::BasicEvolutionaryState)
    evaluation_time_start = time()
    state.evaluations = evaluate(
        [species_creator.evaluator for species_creator in state.ecosystem_creator.species_creators],
        state.rng,
        state.ecosystem.species,
        get_individual_outcomes(state.results), 
    )
    state.evaluation_time = round(time() - evaluation_time_start; digits = 3)
end

function archive!(state::BasicEvolutionaryState)
    for archiver in state.archivers
        archive!(archiver, state)
    end
end

function next_generation!(state::BasicEvolutionaryState)
    state.generation += 1
    #println("starting creation")
    update_ecosystem!(state)
    #println("starting simulation")
    perform_simulation!(state)
    #println("starting evaluation")
    perform_evaluation!(state)
    #println("starting archiving")
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

struct PrimerState{C <: Configuration, R <: Reproducer} <: State
    rng::AbstractRNG
    id::Int
    configuration::C
    n_population::Int
    reproducer::R
end

function Base.getproperty(state::PrimerState, property::Symbol)
    if property in reproducer_properties
        return getproperty(state.reproducer, property)
    else
        return getproperty(state, property)
    end
end

function create_ecosystem(state::PrimerState,)
    ecosystem = create_ecosystem(state.ecosystem_creator, state.id, state)
    return ecosystem
end

function BasicEvolutionaryState(
    config::Configuration, id::Int, seed::Int
)
    rng = StableRNG(seed)
    reproducer = create_reproducer(config)
    simulator = create_simulator(config)
    evaluator = create_evaluator(config)
    archivers = create_archivers(config)
    primer_state = PrimerState(rng, id, config, config.n_population, reproducer)
    ecosystem = create_ecosystem(primer_state)

    state = BasicEvolutionaryState(
        id = id,
        configuration = config,
        generation = 0,
        rng = rng,
        reproducer = reproducer,
        simulator = simulator,
        evaluator = evaluator,
        ecosystem = ecosystem,
        archivers = archivers
    )
    perform_simulation!(state)
    perform_evaluation!(state)
    return state
end
end