module TopologyConfigurations

export Basic, Modes

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

include("modes/modes.jl")
using .Modes: Modes, ModesTopologyConfiguration

end