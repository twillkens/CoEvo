export make_archivers

import ...ExperimentConfigurations: make_archivers

using ....Archivers.Globals: GlobalStateArchiver
using ....Archivers.Fitness: FitnessArchiver
using ....Archivers.GenotypeSize: GenotypeSizeArchiver
using ....Archivers.Modes: ModesArchiver
using ....Archivers.Ecosystems: EcosystemArchiver, MigrationArchiver

const ID_TO_ARCHIVER_TYPE_MAP = Dict(
    "global_state" => GlobalStateArchiver,
    "fitness" => FitnessArchiver,
    "genotype_size" => GenotypeSizeArchiver,
    "modes" => ModesArchiver,
    "ecosystem" => EcosystemArchiver,
)

function make_archivers(config::PredictionGameExperimentConfiguration)
    archive_interval = config.archive.archive_interval
    archive_directory = ENV["COEVO_TRIAL_DIR"] * "/" * config.id
    archivers = [
        GlobalStateArchiver(archive_interval, archive_directory),
        FitnessArchiver(archive_interval, archive_directory),
        GenotypeSizeArchiver(archive_interval, archive_directory),
        ModesArchiver(archive_interval, archive_directory),
        MigrationArchiver(archive_interval, archive_directory),
        EcosystemArchiver(archive_interval, archive_directory),
    ]
    return archivers
end