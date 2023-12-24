export load_game, get_game, ID_TO_GAME_MAP

using HDF5: File
using ...GameConfigurations.ContinuousPredictionGame: ContinuousPredictionGameConfiguration
using ...GameConfigurations.CollisionGame: CollisionGameConfiguration
using ...GameConfigurations.LinguisticPredictionGame: LinguisticPredictionGameConfiguration
using ...NewConfigurations: load_type

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