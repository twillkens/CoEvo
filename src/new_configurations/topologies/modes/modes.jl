module Modes

export ModesTopologyConfiguration

using ...TopologyConfigurations: TopologyConfiguration
using ...TopologyConfigurations.Basic: BasicInteractionConfiguration

Base.@kwdef struct ModesTopologyConfiguration <: TopologyConfiguration
    id::String
    species_ids::Vector{String}
    interactions::Vector{BasicInteractionConfiguration}
    modes_interval::Int
    n_elites::Int
end

end