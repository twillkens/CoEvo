using ...ExperimentConfigurations: ExperimentConfiguration
using ...TopologyConfigurations: TopologyConfiguration
using ...GlobalConfigurations: GlobalConfiguration
using ...GameConfigurations: GameConfiguration
using ...SubstrateConfigurations: SubstrateConfiguration
using ...ReproductionConfigurations: ReproductionConfiguration
using ...ArchiveConfigurations: ArchiveConfiguration

struct PredictionGameExperimentConfiguration{
    G1 <: GlobalConfiguration,
    G2 <: GameConfiguration, 
    T <: TopologyConfiguration, 
    S <: SubstrateConfiguration, 
    R1 <: ReproductionConfiguration, 
    A <: ArchiveConfiguration,
} <: ExperimentConfiguration
    id::String
    globals::G1
    game::G2
    topology::T
    substrate::S
    reproduction::R1
    archive::A
end

function PredictionGameExperimentConfiguration(
    globals::GlobalConfiguration,
    game::GameConfiguration,
    topology::TopologyConfiguration,
    substrate::SubstrateConfiguration,
    reproduction::ReproductionConfiguration,
    archive::ArchiveConfiguration,
)
    ids = [game.id, topology.id, substrate.id, reproduction.id, globals.trial]
    id = joinpath(string.(ids))
    configuration = PredictionGameExperimentConfiguration(
        id,
        globals,
        game,
        topology,
        substrate,
        reproduction,
        archive,
    )
    return configuration
end
