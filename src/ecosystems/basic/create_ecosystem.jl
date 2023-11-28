
function create_ecosystem(
    ecosystem_creator::BasicEcosystemCreator,
    generation::Int, 
    last_reproduction_time::Float64,
    evaluation_time::Float64,
    ecosystem::Ecosystem, 
    results::Vector{<:Result}, 
)
    individual_outcomes = get_individual_outcomes(results)
    observations = get_observations(results)
    evaluations = evaluate(
        ecosystem_creator, ecosystem, individual_outcomes, observations
    )
    state = create_state(
        ecosystem_creator.state_creator, 
        ecosystem_creator, 
        generation, 
        last_reproduction_time,
        evaluation_time,
        ecosystem, 
        individual_outcomes,
        evaluations,
        observations,
    )
    reports = create_reports(ecosystem_creator.reporters, state)
    archive!(ecosystem_creator.archiver, reports)
    if generation % ecosystem_creator.garbage_collection_interval == 0
        Base.GC.gc()
    end
    flush(stdout)
    all_new_species = create_species(ecosystem_creator.species_creators, state)
    new_ecosystem = BasicEcosystem(ecosystem_creator.id, all_new_species)
    
    return new_ecosystem
end