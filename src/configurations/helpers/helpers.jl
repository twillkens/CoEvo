export make_counters, make_random_number_generator, make_performer, make_recombiner
export make_replacer, make_matchmaker, make_ecosystem_creator, evolve!

function make_counters(configuration::Configuration)
    individual_id_counter = BasicCounter(configuration.individual_id_counter_state)
    gene_id_counter = BasicCounter(configuration.gene_id_counter_state)
    return individual_id_counter, gene_id_counter
end

function make_random_number_generator(configuration::Configuration)
    seed = configuration.seed
    random_number_generator = configuration.random_number_generator
    if random_number_generator === nothing
        random_number_generator = StableRNG(seed)
    end
    return random_number_generator
end

function make_performer(configuration::Configuration)
    performer = configuration.performer
    if performer == :cache
        return CachePerformer(n_workers = configuration.n_workers)
    else
        throw(ArgumentError("Unrecognized performer: $performer"))
    end
end

function make_recombiner(configuration::Configuration)
    recombiner = configuration.recombiner
    if recombiner == :clone
        return CloneRecombiner()
    else
        throw(ArgumentError("Unrecognized recombiner: $recombiner"))
    end
end

function make_replacer(configuration::Configuration)
    replacer = configuration.replacer
    if replacer == :truncation
        return TruncationReplacer(n_truncate = configuration.n_truncate)
    else
        throw(ArgumentError("Unrecognized replacer: $replacer"))
    end
end

function make_selector(configuration::Configuration)
    reproduction_method = configuration.reproduction_method
    if reproduction_method == :roulette
        selector = FitnessProportionateSelector(n_parents = configuration.n_population)
    elseif reproduction_method == :disco
        selector = TournamentSelector(
            n_parents = configuration.n_population, 
            tournament_size = configuration.tournament_size
        )
    else
        throw(ArgumentError("Unrecognized reproduction method: $reproduction_method"))
    end
    return selector
end

function make_evaluator(configuration::Configuration)
    reproduction_method = configuration.reproduction_method
    if reproduction_method == :roulette
        evaluator = ScalarFitnessEvaluator()
    elseif reproduction_method == :disco
        evaluator = NSGAIIEvaluator(
            maximize = true, perform_disco = true, max_clusters = configuration.max_clusters,
        )
    else
        throw(ArgumentError("Unrecognized reproduction method: $reproduction_method"))
    end
    return evaluator
end


function make_matchmaker(configuration::Configuration)
    matchmaker = configuration.matchmaker
    if matchmaker == :all_vs_all
        return AllvsAllMatchMaker(cohorts = configuration.cohorts)
    else
        throw(ArgumentError("Unrecognized matchmaker: $matchmaker"))
    end
end

function make_job_creator(configuration::Configuration)
    interactions = make_interactions(configuration)
    job_creator = BasicJobCreator(
        n_workers = configuration.n_workers, interactions = interactions
    )
    return job_creator
end

function make_archiver(configuration::Configuration)
    archive_path = make_archive_path(configuration)
    archiver = BasicArchiver(archive_path = archive_path)
    return archiver
end

function make_state_creator(configuration::Configuration)
    state_creator = configuration.state_creator
    if state_creator == :basic_coevolutionary
        state_creator = BasicCoevolutionaryStateCreator()
    else
        throw(ArgumentError("Unrecognized state creator: $state_creator"))
    end
    return state_creator
end

function make_ecosystem_creator(configuration::Configuration)
    id = make_ecosystem_id(configuration)
    trial = configuration.trial
    random_number_generator = make_random_number_generator(configuration)
    species_creators = make_species_creators(configuration)
    job_creator = make_job_creator(configuration)
    performer = make_performer(configuration)
    state_creator = make_state_creator(configuration)
    runtime_reporter, reporters = make_reporters(configuration)
    archiver = make_archiver(configuration)
    individual_id_counter, gene_id_counter = make_counters(configuration)
    ecosystem_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        random_number_generator = random_number_generator,
        species_creators = species_creators,
        job_creator = job_creator,
        performer = performer,
        state_creator = state_creator,
        reporters = reporters,
        archiver = archiver,
        individual_id_counter = individual_id_counter,
        gene_id_counter = gene_id_counter,
        runtime_reporter = runtime_reporter,
    )
    return ecosystem_creator
end

function evolve!(configuration::Configuration; n_generations::Int = 100)
    ecosystem_creator = make_ecosystem_creator(configuration)
    archive_path = ecosystem_creator.archiver.archive_path
    dir_path = dirname(archive_path)

    # Check if the file exists
    if isfile(archive_path)
        throw(ArgumentError("File already exists: $archive_path"))
    end
    mkpath(dir_path)
    if configuration.report_type in [:deploy]
        @save archive_path configuration = configuration
    end
    ecosystem = evolve!(ecosystem_creator, n_generations = n_generations)
    return ecosystem
end
