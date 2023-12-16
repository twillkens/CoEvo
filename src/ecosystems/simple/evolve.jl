
using ...SpeciesCreators: get_phenotype_creators

function create_jobs(ecosystem_creator::SimpleEcosystemCreator, ecosystem::BasicEcosystem)
    phenotype_creators = get_phenotype_creators(ecosystem_creator.species_creators)
    jobs = create_jobs(
        ecosystem_creator.job_creator,
        ecosystem_creator.global_state.rng, 
        ecosystem.species,
        phenotype_creators,
    )
    return jobs
end

function evolve!(
    ecosystem_creator::SimpleEcosystemCreator,
    ecosystem::BasicEcosystem,
    generations::UnitRange{Int},
)
    last_reproduction_time = 0.0
    for generation in generations
        evaluation_time_start = time()
        jobs = create_jobs(ecosystem_creator, ecosystem)
        results = perform(ecosystem_creator.performer, jobs)
        evaluation_time = time() - evaluation_time_start
        last_reproduction_time_start = time()
        ecosystem = create_ecosystem(
            ecosystem_creator, 
            generation, 
            last_reproduction_time,
            evaluation_time, ecosystem, results
        )
        last_reproduction_time = time() - last_reproduction_time_start
    end

    return ecosystem
end


function evolve!(
    ecosystem_creator::SimpleEcosystemCreator,
    ecosystem::BasicEcosystem,
    n_generations::Int = 100,
)
    generations = UnitRange(1, n_generations)
    ecosystem = evolve!(ecosystem_creator, ecosystem, generations)
    return ecosystem

end

function evolve!(ecosystem_creator::SimpleEcosystemCreator; n_generations::Int = 100)
    ecosystem = create_ecosystem(ecosystem_creator)
    state = create_state(ecosystem_creator.state_creator, ecosystem)
    ecosystem = evolve!(ecosystem_creator, ecosystem, n_generations)
    return ecosystem
end

function evolve!(experiment::BasicExperiment)
    ecosystem_creator = make_ecosystem_creator(experiment)

    global_state = GlobalState()
end