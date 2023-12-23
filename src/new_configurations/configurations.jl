module NewConfigurations

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("globals/globals.jl")
using .GlobalConfigurations: GlobalConfigurations

include("topologies/topologies.jl")
using .TopologyConfigurations: TopologyConfigurations

include("games/games.jl")
using .GameConfigurations: GameConfigurations

include("substrates/substrates.jl")
using .SubstrateConfigurations: SubstrateConfigurations

include("reproduction/reproduction.jl")
using .ReproductionConfigurations: ReproductionConfigurations

include("archives/archives.jl")
using .ArchiveConfigurations: ArchiveConfigurations

include("experiments/experiments.jl")
using .ExperimentConfigurations: ExperimentConfigurations

end