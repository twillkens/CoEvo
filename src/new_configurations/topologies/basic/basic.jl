module Basic

export BasicTopologyConfiguration, BasicInteractionConfiguration, get_id

using HDF5: File
using ...TopologyConfigurations: TopologyConfiguration, InteractionConfiguration

Base.@kwdef struct BasicInteractionConfiguration <: InteractionConfiguration
    id::String = "interactions"
    species_ids::Vector{String}
    domain::String
end

function get_id(interaction_setup::BasicInteractionConfiguration)
    domain = interaction_setup.domain
    species_ids = interaction_setup.species_ids
    id = join([domain, species_ids...], "-")
    return id
end

Base.@kwdef struct BasicTopologyConfiguration{I <: InteractionConfiguration} <: TopologyConfiguration
    id::String
    species_ids::Vector{String}
    interactions::Vector{I}
end

end