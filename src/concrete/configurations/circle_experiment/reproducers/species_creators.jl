using ...SpeciesCreators.Archive: ArchiveSpeciesCreator

const SPECIES_CREATORS = Dict(
    "small" => ArchiveSpeciesCreator(
        n_population = 100,
        n_parents = 50,
        n_children = 50,
        n_elites = 50,
        n_archive = 0,
        archive_interval = 0,
        max_archive_length = 0,
        max_archive_matches = 0,
    ),
    "large" => ArchiveSpeciesCreator(
        n_population = 200,
        n_parents = 100,
        n_children = 100,
        n_elites = 100,
        n_archive = 0,
        archive_interval = 1,
        max_archive_length = 10_000,
        max_archive_matches = 50
    ),
    "small_archive" => ArchiveSpeciesCreator(
        n_population = 100,
        n_parents = 50,
        n_children = 50,
        n_elites = 50,
        n_archive = 3,
        archive_interval = 1,
        max_archive_length = 10_000,
        max_archive_matches = 50,
    ),
    "large_archive" => ArchiveSpeciesCreator(
        n_population = 200,
        n_parents = 100,
        n_children = 100,
        n_elites = 100,
        n_archive = 3,
        archive_interval = 1,
        max_archive_length = 10_000,
        max_archive_matches = 50
    ),
)