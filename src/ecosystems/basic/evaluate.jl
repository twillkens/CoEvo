using ...SpeciesCreators: get_evaluators

function evaluate(
    ecosystem_creator::BasicEcosystemCreator, 
    ecosystem::Ecosystem, 
    individual_outcomes::Dict{Int, Dict{Int, Float64}}, 
    observations::Vector{<:Observation}
)
    #evaluators = [
    #    species_creator.evaluator for species_creator in ecosystem_creator.species_creators
    #]
    evaluators = get_evaluators(ecosystem_creator.species_creators)
    evaluations = evaluate(
        evaluators, 
        ecosystem_creator.random_number_generator, 
        ecosystem.species, 
        individual_outcomes, 
        #observations
    )
    return evaluations
end
