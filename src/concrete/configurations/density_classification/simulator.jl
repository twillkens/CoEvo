import ....Interfaces: create_simulator
using ...Environments.ElementaryCellularAutomata: ElementaryCellularAutomataEnvironmentCreator
#using ...Environments.ECAOptimized: ElementaryCellularAutomataEnvironmentCreator

function create_simulator(config::DensityClassificationExperimentConfiguration) 
    simulator = BasicSimulator(
        interactions = [
            BasicInteraction(
                id = "numbers_game",
                environment_creator = ElementaryCellularAutomataEnvironmentCreator(
                    domain = DensityClassificationDomain("Covers")
                ),
                species_ids = ["R", "IC"],
            )
        ],
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers),
        performer = CachePerformer(n_workers = config.n_workers),
    )
    return simulator
end
