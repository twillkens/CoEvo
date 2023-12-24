export make_archivers

using ....Archivers.Globals: GlobalStateArchiver
using ....Archivers.Fitness: FitnessArchiver
using ....Archivers.GenotypeSize: GenotypeSizeArchiver
using ....Archivers.Modes: ModesArchiver

const ID_TO_ARCHIVER_TYPE_MAP = Dict(
    "global_state" => GlobalStateArchiver,
    "fitness" => FitnessArchiver,
    "genotype_size" => GenotypeSizeArchiver,
    "modes" => ModesArchiver,
)

function make_archivers(config::PredictionGameExperimentConfiguration)
    archive_interval = config.archive.archive_interval
    archive_path = ENV["COEVO_TRIAL_DIR"] * "/" * config.id * ".h5"
    archivers = [
        GlobalStateArchiver(archive_interval, archive_path),
        FitnessArchiver(archive_interval, archive_path),
        GenotypeSizeArchiver(archive_interval, archive_path),
        ModesArchiver(archive_interval, archive_path),
    ]
    return archivers
end