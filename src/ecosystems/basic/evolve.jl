
function evolve!(
    ecosystem_creator::BasicEcosystemCreator;
    n_generations::Int = 100,
)
    ecosystem = create_ecosystem(ecosystem_creator)
    last_reproduction_time = 0.0
    for generation in 1:n_generations
        evaluation_time_start = time()
        phenotype_creators = [
            species_creator.phenotype_creator 
            for species_creator in ecosystem_creator.species_creators
        ]
        jobs = create_jobs(
            ecosystem_creator.job_creator,
            ecosystem_creator.random_number_generator, 
            ecosystem.species,
            phenotype_creators,
        )
        results = perform(ecosystem_creator.performer, jobs)
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
        last_reproduction_time = time() - last_reproduction_time_start
    end

    return ecosystem
end