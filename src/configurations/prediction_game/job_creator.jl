using ...Names

function make_environment_creator(
    ::LinguisticPredictionGameConfiguration, setup::InteractionSetup
)
    domain = PredictionGameDomain(setup.domain)
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain = domain)
    return environment_creator
end

function make_environment_creator(
    configuration::CollisionGameConfiguration, setup::InteractionSetup
)
    domain = PredictionGameDomain(setup.domain)
    initial_distance = configuration.initial_distance
    episode_length = configuration.episode_length
    communication_dimension = configuration.communication_dimension
    environment_creator = CollisionGameEnvironmentCreator(
        domain = domain,
        initial_distance = initial_distance,
        episode_length = episode_length,
        communication_dimension = communication_dimension
    )
    return environment_creator
end


function make_environment_creator(
    game::ContinuousPredictionGameConfiguration, setup::InteractionSetup
)
    domain = PredictionGameDomain(setup.domain)
    episode_length = game.episode_length
    communication_dimension = game.communication_dimension
    environment_creator = ContinuousPredictionGameEnvironmentCreator(
        domain = domain,
        episode_length = episode_length,
        communication_dimension = communication_dimension
    )
    return environment_creator
end


function make_interaction(
    game::GameConfiguration, 
    interaction_setup::InteractionSetup, 
    cohorts::Vector{String}
)
    interaction = BasicInteraction(
        id = get_id(interaction_setup),
        environment_creator = make_environment_creator(game, interaction_setup),
        species_ids = interaction_setup.species_ids,
        matchmaker = AllVersusAllMatchMaker(cohorts = cohorts),
    )
    return interaction
end

function make_interactions(game::GameConfiguration, topology::Topology)
    interactions = [
        make_interaction(game, interaction_setup, topology.cohorts)
        for interaction_setup in topology.interactions
    ]
    return interactions
end

function make_job_creator(
    globals::GlobalConfiguration, 
    game::GameConfiguration, 
    topology::Topology, 
)
    job_creator = BasicJobCreator(
        n_workers = get_n_workers(globals), 
        interactions = make_interactions(game, topology)
    )
    return job_creator
end
