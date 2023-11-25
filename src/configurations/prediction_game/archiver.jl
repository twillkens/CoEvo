export make_archive_path, make_archiver, create_archive, archive!

function make_archive_path(
    game::GameConfiguration, 
    topology::Topology, 
    substrate::Substrate, 
    reproducer::Reproducer, 
    globals::GlobalConfiguration
)
    trial = get_trial(globals)
    trial_dir = ENV["COEVO_TRIAL_DIR"]
    path = joinpath(trial_dir, game.id, topology.id, substrate.id, reproducer.id, "$trial.h5")
    return path
end

function create_archive(
    path::String,
    globals::GlobalConfiguration,
    game::GameConfiguration, 
    topology::Topology, 
    substrate::Substrate, 
    reproducer::Reproducer, 
    report::ReportConfiguration
)
    if !requires_archive(report)
        return
    end
    if isfile(path)
        throw(ArgumentError("File already exists: $path"))
    end
    dir_path = dirname(path)
    mkpath(dir_path)
    file = h5open(path, "w")
    archive!(globals, file)
    archive!(game, file)
    archive!(topology, file)
    archive!(substrate, file)
    archive!(reproducer, file)
    archive!(report, file)
    close(file)
end

function make_archiver(
    game::GameConfiguration,
    topology::Topology,
    substrate::Substrate,
    reproducer::Reproducer,
    globals::GlobalConfiguration,
)
    path = make_archive_path(game, topology, substrate, reproducer, globals)
    archiver = BasicArchiver(path)
    return archiver
end