export GameConfiguration, ContinuousPredictionGameConfiguration, load_game, get_game

abstract type GameConfiguration end

struct LinguisticPredictionGameConfiguration <: GameConfiguration
    id::String
end

function archive!(configuration::LinguisticPredictionGameConfiguration, file::File)
    file["configuration/game/id"] = configuration.id
end

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

function archive!(configuration::CollisionGameConfiguration, file::File)
    base_path = "configuration/game"
    file["$base_path/id"] = configuration.id
    file["$base_path/initial_distance"] = configuration.initial_distance
    file["$base_path/episode_length"] = configuration.episode_length
    file["$base_path/communication_dimension"] = configuration.communication_dimension
end

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

function archive!(configuration::ContinuousPredictionGameConfiguration, file::File)
    file["configuration/game/id"] = configuration.id
    file["configuration/game/episode_length"] = configuration.episode_length
    file["configuration/game/communication_dimension"] = configuration.communication_dimension
end

const ID_TO_GAME_MAP = Dict(
    "linguistic_prediction_game" => LinguisticPredictionGameConfiguration,
    "collision_game" => CollisionGameConfiguration,
    "continuous_prediction_game" => ContinuousPredictionGameConfiguration,
)

function load_game(file::File)
    base_path = "configuration/game"
    id = read(file["$base_path/id"])
    game_type = get(ID_TO_GAME_MAP, id, nothing)

    if game_type === nothing
        error("Unknown game type: $id")
    end
    game = load_type(game_type, file, base_path)
    return game
end

function get_game(id::String; kwargs...)
    game_type = get(ID_TO_GAME_MAP, id, nothing)
    if game_type === nothing
        error("Unknown game type: $id")
    end
    game = game_type(; id = id, kwargs...)
    return game
end
