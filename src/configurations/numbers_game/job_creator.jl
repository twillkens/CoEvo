
function make_interactions(configuration::NumbersGameConfiguration)
    species_ids = ["A", "B"]
    id = join([species_ids..., configuration.outcome_metric], "-")
    matchmaker = AllvsAllMatchMaker(cohorts = configuration.cohorts)
    domain = NumbersGameDomain(configuration.outcome_metric)
    environment_creator = StatelessEnvironmentCreator(domain)
    interaction = BasicInteraction(
        id = id,
        environment_creator = environment_creator,
        species_ids = species_ids,
        matchmaker = matchmaker
    )
    interactions = [interaction]
    return interactions
end

function make_job_creator(configuration::NumbersGameConfiguration)
    interactions = make_interactions(configuration)
    job_creator = BasicJobCreator(
        n_workers = configuration.n_workers, interactions = interactions
    )
    return job_creator
end