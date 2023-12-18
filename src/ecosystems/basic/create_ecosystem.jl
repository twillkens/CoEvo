
function create_ecosystem(
    ecosystem_creator::BasicEcosystemCreator,
    generation::Int, 
    last_reproduction_time::Float64,
    evaluation_time::Float64,
    ecosystem::Ecosystem, 
    results::Vector{<:Result}, 
)
    individual_outcomes = get_individual_outcomes(results)
    #println("individual_outcomes: $individual_outcomes")
    observations = get_observations(results)
    #println("before evaluate: ", ecosystem_creator.rng.state)
    evaluations = evaluate(
        ecosystem_creator, ecosystem, individual_outcomes, observations
    )
    #println("before create_state: ", ecosystem_creator.rng.state)
    #println("evaluations: $evaluations")
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
    #println("before reports: ", ecosystem_creator.rng.state)
    reports = create_reports(ecosystem_creator.reporters, state)
    archive!(ecosystem_creator.archiver, reports)
    if generation % ecosystem_creator.garbage_collection_interval == 0
        Base.GC.gc()
    end
    flush(stdout)
    #println("before all_new_species: ", ecosystem_creator.rng.state)
    all_new_species = create_species(ecosystem_creator.species_creators, state)
    #println("before new ecosystem: ", ecosystem_creator.rng.state)
    new_ecosystem = BasicEcosystem(ecosystem_creator.id, all_new_species)
    
    return new_ecosystem
end