export run!

function run!(configuration::PredictionGameConfiguration; n_generations::Int = 100)
    ecosystem_creator = make_ecosystem_creator(configuration)
    archive_path = ecosystem_creator.archiver.archive_path
    dir_path = dirname(archive_path)
    # Check if the file exists
    mkpath(dir_path)
    if configuration.report_type in ["deploy"]
        if isfile(archive_path)
            throw(ArgumentError("File already exists: $archive_path"))
        end
        h5write(archive_path, "configuration", configuration)
    end
    ecosystem = evolve!(ecosystem_creator, n_generations = n_generations)
    return ecosystem
end