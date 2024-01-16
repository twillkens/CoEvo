export create_primer, create_state, create_state_from_dict, convert_to_dict

import ....Interfaces: convert_to_dict, create_state_from_dict
using StableRNGs
using HDF5
using ....Abstract
using ....Interfaces
using ...States.Primer: PrimerState
using ...States.Basic: BasicEvolutionaryState, Timers
using ...Archivers.Ecosystems: EcosystemArchiver
using ...Counters.Step: StepCounter

function create_primer(config::CircleExperimentConfiguration, generation::Int, rng::AbstractRNG)
    reproducer = create_reproducer(config)
    simulator = create_simulator(config)
    evaluator = create_evaluator(config)
    primer_state = PrimerState(
        id = config.id, 
        configuration = config, 
        generation = generation,
        rng = rng, 
        reproducer = reproducer,
        simulator = simulator,
        evaluator = evaluator
    )
    return primer_state
end

create_primer(config::CircleExperimentConfiguration) = create_primer(config, 1, StableRNG(config.seed))

function create_state(config::CircleExperimentConfiguration)
    state = create_primer(config)
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

function convert_to_dict(state::BasicEvolutionaryState, ::CircleExperimentConfiguration)
    println("saving_rng_state = $(state.rng_state_after_reproduction)")
    dict = Dict(
        "generation" => state.generation,
        "rng_state" => state.rng_state_after_reproduction,
        "ecosystem" => convert_to_dict(state.ecosystem),
        "current_individual_id" => state.reproducer.individual_id_counter.current_value,
        "current_gene_id" => state.reproducer.gene_id_counter.current_value,
    )
    return dict
end

function create_state_from_dict(dict::Dict, config::CircleExperimentConfiguration)
    rng_state_after_reproduction = parse(UInt128, dict["rng_state"])
    println("loaded_rng_state_after_reproduction = $rng_state_after_reproduction")
    rng = StableRNG(state = rng_state_after_reproduction)
    generation = dict["generation"]
    individual_id_counter = StepCounter(dict["current_individual_id"], config.n_ecosystems)
    gene_id_counter = StepCounter(dict["current_gene_id"], config.n_ecosystems)
    state = create_primer(config, generation, rng)
    state.reproducer.individual_id_counter = individual_id_counter
    state.reproducer.gene_id_counter = gene_id_counter
    ecosystem = create_from_dict(state.reproducer.ecosystem_creator, dict["ecosystem"], state)
    order_dict = Dict(id => index for (index, id) in enumerate(state.reproducer.species_ids))

# Now, sort x in place
    sort!(ecosystem.all_species, by = species -> order_dict[species.id])
    for species in ecosystem.all_species
        sort!(species.population, by = individual -> individual.id)
    end
    results, simulation_time = simulate_with_time(state.simulator, ecosystem, state)
    evaluations, evaluation_time = evaluate_with_time(state.evaluator, ecosystem, results, state)
    println("loaded_rng_after_evaluation = $(state.rng.state)")
    archivers = create_archivers(config)
    timers = Timers(0.0, simulation_time, evaluation_time)
    state = BasicEvolutionaryState(
        id = config.id,
        configuration = config,
        generation = generation,
        rng = state.rng,
        rng_state_after_reproduction = dict["rng_state"],
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
    return state
end