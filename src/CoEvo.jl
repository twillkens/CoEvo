module CoEvo

export CoevolutionaryEcosystemConfiguration, EcoCfg

include("abstract/abstract.jl")
include("ecosystems/ecosystems.jl")

using .Ecosystems: CoevolutionaryEcosystemConfiguration

const EcoCfg = CoevolutionaryEcosystemConfiguration

end