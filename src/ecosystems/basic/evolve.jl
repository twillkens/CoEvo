
using ...SpeciesCreators: get_phenotype_creators

function evolve!(
    ecosystem_creator::BasicEcosystemCreator,
    ecosystem::BasicEcosystem,
    generations::UnitRange{Int},
)
    last_reproduction_time = 0.0
    for generation in generations
        evaluation_time_start = time()
        phenotype_creators = get_phenotype_creators(ecosystem_creator.species_creators)
        jobs = create_jobs(
            ecosystem_creator.job_creator,
            ecosystem_creator.rng, 
            ecosystem.species,
            phenotype_creators,
        )
        #println("evolve! ", ecosystem_creator.rng.state)
        results = perform(ecosystem_creator.performer, jobs)
        #println("after perform ", ecosystem_creator.rng.state)
        evaluation_time = time() - evaluation_time_start
        last_reproduction_time_start = time()
        ecosystem = create_ecosystem(
            ecosystem_creator, 
            generation, 
            last_reproduction_time,
            evaluation_time,
            ecosystem, 
            results
        )
        #println("after create_ecosystem ", ecosystem_creator.rng.state)
        last_reproduction_time = time() - last_reproduction_time_start
    end

    return ecosystem
end


function evolve!(
    ecosystem_creator::BasicEcosystemCreator,
    ecosystem::BasicEcosystem,
    n_generations::Int = 100,
)
    generations = UnitRange(1, n_generations)
    ecosystem = evolve!(ecosystem_creator, ecosystem, generations)
    return ecosystem

end

function evolve!(ecosystem_creator::BasicEcosystemCreator; n_generations::Int = 100)
    #println("before create: ", ecosystem_creator.rng.state)
    ecosystem = create_ecosystem(ecosystem_creator)
    #println("after create: ", ecosystem_creator.rng.state)
    ecosystem = evolve!(ecosystem_creator, ecosystem, n_generations)
    return ecosystem
end