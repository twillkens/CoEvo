
module Runners

include("cont_pred_threemix_gnarl_disco.jl")
using .ContinuousPredictionGameThreeMixGnarlDisco: cont_pred_threemix_gnarl_disco_eco_creator

include("cont_pred_threemix_gnarl_roulette.jl")
using .ContinuousPredictionGameThreeMixGnarlRoulette: cont_pred_threemix_gnarl_roulette_eco_creator

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
    n_gen::Int = 5_000
)
    load_interface(trial, "Starting")
    eco_creator_dict = Dict(
        "ContinuousPredictionGameThreeMixGnarlDisco" => 
            cont_pred_threemix_gnarl_disco_eco_creator,
        "ContinuousPredictionGameThreeMixGnarlRoulette" => 
            cont_pred_threemix_gnarl_roulette_eco_creator
    )
    eco_creator = eco_creator_dict[id]
    rng = StableRNG(seed)
    
    eco_creator = eco_creator(trial=trial, id = id, rng = rng)
    eco = evolve!(eco_creator, n_gen = n_gen)
    
    load_interface(trial, "Completed")
    return eco
end

end