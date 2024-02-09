
function create_simulator(config::NumbersGameExperimentConfiguration) 
    simulator = BasicSimulator(
        interactions = [
            BasicInteraction(
                id = "numbers_game",
                environment_creator = StatelessEnvironmentCreator(
                    domain = NumbersGameDomain(config.domain)
                ),
                species_ids = ["A", "B"],
            )
        ],
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers),
        performer = CachePerformer(n_workers = config.n_workers),
    )
    return simulator
end
