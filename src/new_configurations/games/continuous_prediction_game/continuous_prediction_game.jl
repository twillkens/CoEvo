module ContinuousPredictionGame

export ContinuousPredictionGameConfiguration

import ...GameConfigurations: make_environment_creator

using ...GameConfigurations: GameConfiguration
using ....Environments.ContinuousPredictionGame: ContinuousPredictionGameEnvironmentCreator
using ....Domains.PredictionGame: PredictionGameDomain
using ...TopologyConfigurations.Basic: BasicInteractionConfiguration

struct ContinuousPredictionGameConfiguration <: GameConfiguration
    id::String
    episode_length::Int
    communication_dimension::Int
end

function ContinuousPredictionGameConfiguration(;
    id::String = "continuous_prediction_game",
    episode_length::Int = 16, 
    communication_dimension::Int = 0, 
    kwargs...
)
    configuration = ContinuousPredictionGameConfiguration(
        id, episode_length, communication_dimension
    )
    return configuration
end

function make_environment_creator(
    game::ContinuousPredictionGameConfiguration, setup::BasicInteractionConfiguration
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
end