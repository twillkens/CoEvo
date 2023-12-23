export get_archive

using ...ArchiveConfigurations.Modes: ModesArchiveConfiguration

const ID_TO_ARCHIVES_MAP = Dict(
    "basic" => ["global_state", "fitness", "genotype_size"],
    "modes" => ["global_state", "fitness", "genotype_size", "modes"],
)

function load_archive(file::File)
    base_path = "configuration/archive"
    id = read(file["$base_path/id"])
    archive_interval = read(file["$base_path/archive_interval"])
    modes_interval = read(file["$base_path/modes_interval"])
    archivers = read(file["$base_path/archivers"])
    config = ModesArchiveConfiguration(id, archive_interval, modes_interval, archivers)
    return config
end

function get_archive(id::String; archive_interval::Int = 50, modes_interval::Int = 50, kwargs...)
    configuration = ModesArchiveConfiguration(
        id = id, 
        archive_interval = archive_interval,
        modes_interval = modes_interval,
        archivers = ["global_state", "fitness", "genotype_size", "modes"],
    )
    return configuration
end