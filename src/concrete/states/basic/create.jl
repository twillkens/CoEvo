
#function BasicEvolutionaryState(config::Configuration, checkpoint_path::String)
#    state = PrimerState(config)
#    file = h5open(checkpoint_path, "r")
#    generation = read(file["generation"])
#    rng_state = parse(UInt128, file["rng_state"])
#    rng = StableRNG(rng_state)
#
#    ecosystem, reproduction_time = create_ecosystem(primer_state)
#    rng.state = checkpoint_file["rng_state_after_reproduction"][()]
#    results, simulation_time = perform_simulation(
#        ecosystem, simulator.job_creator, simulator.performer, primer_state
#    )
#    evaluations, evaluation_time = perform_evaluation(
#        ecosystem, evaluator, results, primer_state
#    )
#    close(checkpoint_file)
#    state = BasicEvolutionaryState(
#        id = config.trial,
#        configuration = config,
#        generation = generation,
#        rng = rng,
#        reproducer = reproducer,
#        reproduction_time = reproduction_time,
#        rng_state_after_reproduction = rng_state,
#        simulator = simulator,
#        simulation_time = simulation_time,
#        evaluator = evaluator,
#        evaluation_time = evaluation_time,
#        ecosystem = ecosystem,
#        results = results,
#        evaluations = evaluations,
#        archivers = archivers
#    )
#    return state
#end