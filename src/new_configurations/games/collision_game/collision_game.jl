module CollisionGame

export CollisionGameConfiguration

import ...GameConfigurations: make_environment_creator

using ...GameConfigurations: GameConfiguration
using ....Environments.CollisionGame: CollisionGameEnvironmentCreator
using ....Domains.PredictionGame: PredictionGameDomain
using ...TopologyConfigurations.Basic: BasicInteractionConfiguration

struct CollisionGameConfiguration <: GameConfiguration
    id::String
    initial_distance::Float64
    episode_length::Int
    communication_dimension::Int
end

function CollisionGameConfiguration(;
    id::String = "collision_game",
    initial_distance::Float64 = 0.5,
    episode_length::Int = 16, 
    communication_dimension::Int = 1, 
    kwargs...
)
    configuration = CollisionGameConfiguration(
        id, initial_distance, episode_length, communication_dimension
    )
    return configuration
end

function make_environment_creator(
    configuration::CollisionGameConfiguration, setup::BasicInteractionConfiguration
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

end