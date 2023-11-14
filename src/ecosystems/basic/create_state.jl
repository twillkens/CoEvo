
function create_state(
    ::BasicCoevolutionaryStateCreator,
    ecosystem_creator::BasicEcosystemCreator,
    generation::Int,
    last_reproduction_time::Float64,
    evaluation_time::Float64,
    ecosystem::Ecosystem,
    individual_outcomes::Dict{Int, Dict{Int, Float64}},
    evaluations::Vector{<:Evaluation},
    observations::Vector{<:Observation},
)
    state = BasicCoevolutionaryState(
        id = ecosystem_creator.id,
        random_number_generator = ecosystem_creator.random_number_generator,
        trial = ecosystem_creator.trial,
        generation = generation,
        last_reproduction_time = last_reproduction_time,
        evaluation_time = evaluation_time,
        individual_id_counter = ecosystem_creator.individual_id_counter,
        gene_id_counter = ecosystem_creator.gene_id_counter,
        species = ecosystem.species,
        individual_outcomes = individual_outcomes,
        evaluations = evaluations,
        observations = observations,
    )
    return state
end
