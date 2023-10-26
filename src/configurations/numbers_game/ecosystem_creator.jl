
function make_ecosystem_id(configuration::NumbersGameConfiguration)
    reproduction_method = configuration.reproduction_method
    outcome_metric = configuration.outcome_metric
    n_population = configuration.n_population
    trial = configuration.trial
    id = join([reproduction_method, outcome_metric, n_population, trial], "-")
    return id
end

function make_archive_path(configuration::NumbersGameConfiguration)
    outcome_metric = configuration.outcome_metric
    reproduction_method = configuration.reproduction_method
    trial = configuration.trial
    jld2_path = "trials/numbers_game/$outcome_metric/$reproduction_method/$trial.jld2"
    return jld2_path
end

function make_ecosystem_creator(configuration::NumbersGameConfiguration)
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