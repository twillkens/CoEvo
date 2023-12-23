export TopologyConfiguration, InteractionConfiguration

using ...NewConfigurations: Configuration

abstract type InteractionConfiguration <: Configuration end

abstract type TopologyConfiguration <: Configuration end
