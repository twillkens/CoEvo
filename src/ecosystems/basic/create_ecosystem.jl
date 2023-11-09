
function create_ecosystem(
    ecosystem_creator::BasicEcosystemCreator,
    generation::Int, 
    last_reproduction_time::Float64,
    evaluation_time::Float64,
    ecosystem::Ecosystem, 
    results::Vector{<:Result}, 
    reports::Vector{Report}
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
    generation_reports = create_reports(state, ecosystem_creator.reporters)
    append!(reports, generation_reports)
    archive!(ecosystem_creator.archiver, reports)
    if generation % ecosystem_creator.garbage_collection_interval == 0
        Base.GC.gc()
    end
    all_new_species = create_species(state, ecosystem_creator.species_creators)
    new_ecosystem = BasicEcosystem(ecosystem_creator.id, all_new_species)
    
    return new_ecosystem
end