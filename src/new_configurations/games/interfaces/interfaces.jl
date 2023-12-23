export make_environment_creator

using ..TopologyConfigurations: TopologyConfiguration, InteractionConfiguration

function make_environment_creator(
    game::GameConfiguration, ::InteractionConfiguration
)
    throw(ErrorException("make_environment_creator not implemented for $(typeof(game))"))
end