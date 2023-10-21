
module Runners

#include("cont_pred_threemix_gnarl_disco.jl")
#using .ContinuousPredictionGameThreeMixGnarlDisco: cont_pred_threemix_gnarl_disco_eco_creator
#
#include("cont_pred_threemix_gnarl_roulette.jl")
#using .ContinuousPredictionGameThreeMixGnarlRoulette: cont_pred_threemix_gnarl_roulette_eco_creator
#
#include("cont_pred_threemix_fg_disco.jl")
#using .ContinuousPredictionGameThreeMixFunctionGraphsDisco: cont_pred_threemix_function_graphs_disco_eco_creator

include("prediction_games.jl")
using .PredictionGames: make_ecosystem_creator, PredictionGameTrialConfiguration

using StableRNGs: StableRNG
using ..Ecosystems.Interfaces: evolve!


# Function to display the loading interface
function load_interface(trial::Int, action::String)
    println("Trial $trial: $action ...")
end

# The evolve function with added print statements
function evolve_trial(
    trial::Int, 
    seed::UInt32 = UInt32(777),
    id::String = "ContinuousPredictionGameThreeMixGnarlRoulette", 
    n_generations::Int = 5_000
)
    load_interface(trial, "Starting")
    eco_creator_dict = Dict(
    #    "ContinuousPredictionGameThreeMixGnarlDisco" => 
    #        cont_pred_threemix_gnarl_disco_eco_creator,
    #    "ContinuousPredictionGameThreeMixGnarlRoulette" => 
    #        cont_pred_threemix_gnarl_roulette_eco_creator,
    #    "ContinuousPredictionGameThreeMixFunctionGraphsDisco" => 
    #        cont_pred_threemix_function_graphs_disco_eco_creator,
        "PredictionGames" => make_prediction_game_eco_creator
            
    )
    ecosystem_creator = eco_creator_dict[id]
    
    ecosystem_creator = ecosystem_creator(trial=trial, seed = seed)
    eco = evolve!(ecosystem_creator, n_generations = n_generations)
    
    load_interface(trial, "Completed")
    return eco
end

end