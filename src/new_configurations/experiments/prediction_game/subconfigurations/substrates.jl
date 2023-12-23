using ...SubstrateConfigurations.FiniteStateMachines: FiniteStateMachineSubstrateConfiguration
using ...SubstrateConfigurations.GnarlNetworks: GnarlNetworkSubstrateConfiguration
using ...SubstrateConfigurations.FunctionGraphs: FunctionGraphSubstrateConfiguration

const ID_TO_SUBSTRATE_MAP = Dict(
    "finite_state_machines" => FiniteStateMachineSubstrateConfiguration,
    "gnarl_networks" => GnarlNetworkSubstrateConfiguration, 
    "function_graphs" => FunctionGraphSubstrateConfiguration,
)

function get_substrate(id::String; kwargs...)
    type = get(ID_TO_SUBSTRATE_MAP, id, nothing)
    if type === nothing
        error("Unknown substrate type: $id")
    end
    substrate = type(; id = id, kwargs...)
    return substrate
end

function load_substrate(file::File)
    base_path = "configuration/substrate"
    substrate_id = read(file["$base_path/id"])
    substrate_type = get(ID_TO_SUBSTRATE_MAP, substrate_id, nothing)

    if substrate_type === nothing
        error("Unknown substrate type: $substrate_id")
    end
    substrate = load_type(substrate_type, file, base_path)
    return substrate
end