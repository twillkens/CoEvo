module SubstrateConfigurations

export FunctionGraphs, FiniteStateMachines, GnarlNetworks

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("function_graphs/function_graphs.jl")
using .FunctionGraphs: FunctionGraphs

include("finite_state_machines/finite_state_machines.jl")
using .FiniteStateMachines: FiniteStateMachines

include("gnarl_networks/gnarl_networks.jl")
using .GnarlNetworks: GnarlNetworks

end