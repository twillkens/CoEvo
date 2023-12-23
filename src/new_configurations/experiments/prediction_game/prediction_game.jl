module PredictionGame

export get_n_generations, make_ecosystem_creator, PredictionGameExperimentConfiguration
export make_job_creator, make_performer

using ...GlobalConfigurations.Basic: BasicGlobalConfiguration

include("subconfigurations/subconfigurations.jl")

include("configuration.jl")

include("create/create.jl")

function PredictionGameExperimentConfiguration(;
    game::String = "continuous_prediction_game",
    topology::String = "two_control",
    substrate::String = "function_graphs",
    reproduction::String = "disco",
    archive::String = "silent",
    kwargs...
)
    globals = get_globals(; kwargs...)
    game = get_game(game; kwargs...)
    topology = get_topology(topology; kwargs...)
    substrate = get_substrate(substrate; kwargs...)
    reproducer = get_reproduction(reproduction; kwargs...)
    archive = get_archive(archive; kwargs...)
    experiment = PredictionGameExperimentConfiguration(
        globals, game, topology, substrate, reproducer, archive
    )
    return experiment
end

end