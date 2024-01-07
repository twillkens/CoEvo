
function make_environment_creator(
    full_config::PredictionGameConfiguration, interaction_config::InteractionConfig
)
    environment_creator = ContinuousPredictionGameEnvironmentCreator(
        domain = PredictionGameDomain(interaction_config.domain),
        episode_length = full_config.episode_length,
        communication_dimension = 0
    )
    return environment_creator
end

function make_interaction(
    full_config::PredictionGameConfiguration, 
    interaction_config::InteractionConfig, 
)
    interaction = BasicInteraction(
        id = get_id(interaction_config),
        environment_creator = make_environment_creator(full_config, interaction_config),
        species_ids = interaction_config.species_ids,
        matchmaker = AllVersusAllMatchMaker(),
    )
    return interaction
end

function make_interactions(full_config::PredictionGameConfiguration, topology_config::TopologyConfig)
    interactions = [
        make_interaction(full_config, interaction_config)
        for interaction_config in topology_config.interactions
    ]
    return interactions
end

function make_job_creator(config::PredictionGameConfiguration)
    topology_config = PREDICTION_GAME_TOPOLOGIES[config.topology]
    job_creator = BasicJobCreator(
        n_workers = config.n_workers_per_ecosystem, 
        interactions = make_interactions(config, topology_config)
    )
    return job_creator
end