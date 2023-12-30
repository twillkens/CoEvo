export PredictionGameExperimentConfiguration, get_root_directory, clip_last_subfield
export get_archive_path, get_archive_directory

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
    elites_type = topology.n_elites > 0 ? "elites" : "no_elites"
    ids = [game.id, topology.id, substrate.id, reproduction.id, elites_type, globals.trial]
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

function clip_last_subfield(directory::String)
    parts = split(directory, "/")
    return join(parts[1:end-1], "/")
end

function get_root_directory(config::PredictionGameExperimentConfiguration)
    root_directory = joinpath(ENV["COEVO_TRIAL_DIR"], clip_last_subfield(config.id))
    return root_directory
end

function get_archive_path(config::PredictionGameExperimentConfiguration)
    archive_path = ENV["COEVO_TRIAL_DIR"] * "/" * config.id * ".h5"
    return archive_path
end

function get_archive_directory(config::PredictionGameExperimentConfiguration)
    archive_directory = ENV["COEVO_TRIAL_DIR"] * "/" * config.id
    return archive_directory
end