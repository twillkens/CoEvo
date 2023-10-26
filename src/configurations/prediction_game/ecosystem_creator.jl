export make_ecosystem_id, make_archive_path, make_ecosystem_creator

function make_ecosystem_id(configuration::PredictionGameConfiguration)
    substrate = configuration.substrate
    reproduction_method = configuration.reproduction_method
    game = configuration.game
    ecosystem_topology = configuration.ecosystem_topology
    n_population = configuration.n_population
    trial = configuration.trial
    id = join(
        [substrate, reproduction_method, game, ecosystem_topology, n_population, trial], "-"
    )
    return id
end

function make_archive_path(configuration::PredictionGameConfiguration)
    substrate = configuration.substrate
    reproduction_method = configuration.reproduction_method
    game = configuration.game
    ecosystem_topology = configuration.ecosystem_topology
    trial = configuration.trial
    jld2_path = "trials/$substrate/$reproduction_method/$game/$ecosystem_topology/$trial.jld2"
    return jld2_path
end

function make_ecosystem_creator(configuration::PredictionGameConfiguration)
    runtime_reporter, reporters = make_reporters(configuration)
    ecosystem_creator = BasicEcosystemCreator(
        id = make_ecosystem_id(configuration),
        trial = trial = configuration.trial,
        random_number_generator = make_random_number_generator(configuration),
        species_creators = make_species_creators(configuration),
        job_creator = make_job_creator(configuration),
        performer = CachePerformer(n_workers = configuration.n_workers),
        state_creator = BasicCoevolutionaryStateCreator(),
        reporters = reporters,
        archiver = BasicArchiver(archive_path = make_archive_path(configuration)),
        individual_id_counter = BasicCounter(),
        gene_id_counter = BasicCounter(),
        runtime_reporter = runtime_reporter,
    )
    return ecosystem_creator
end
