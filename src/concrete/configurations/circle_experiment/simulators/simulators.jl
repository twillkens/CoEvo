
using ....Abstract
using ...Results.Basic: BasicResult
using ...Observers.StateMedian: StateMedianObserver, StateMedianObservation
using ...Performers.Cache: CachePerformer
using ...MatchMakers.AllVersusAll: AllVersusAllMatchMaker
using ...Environments.ContinuousPredictionGame: ContinuousPredictionGameEnvironmentCreator
using ...Domains.PredictionGame: PredictionGameDomain
using ...Interactions.Basic: BasicInteraction
using ...Jobs.Simple
using ...Simulators.Basic: BasicSimulator

function make_environment_creator(
    full_config::CircleExperimentConfiguration, 
    interaction_config::InteractionConfig
)
    environment_creator = ContinuousPredictionGameEnvironmentCreator(
        domain = PredictionGameDomain(interaction_config.domain),
        episode_length = full_config.episode_length,
        communication_dimension = 0
    )
    return environment_creator
end

function make_interaction(
    full_config::CircleExperimentConfiguration, 
    interaction_config::InteractionConfig, 
)
    interaction = BasicInteraction(
        id = get_id(interaction_config),
        environment_creator = make_environment_creator(full_config, interaction_config),
        species_ids = interaction_config.species_ids,
        observer = StateMedianObserver(is_active = false),
    )
    return interaction
end

function make_interactions(
    full_config::CircleExperimentConfiguration, 
    topology_config::TopologyConfig
)
    interactions = [
        make_interaction(full_config, interaction_config)
        for interaction_config in topology_config.interactions
    ]
    return interactions
end


function BasicSimulator(config::CircleExperimentConfiguration)
    simulator = BasicSimulator(
        interactions = make_interactions(config, PREDICTION_GAME_TOPOLOGIES[config.topology]),
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers_per_ecosystem),
        performer = CachePerformer(),
    )
    return simulator
end