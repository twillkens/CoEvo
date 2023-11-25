export make_matches, get_individual_ids_from_cohorts

function make_matches(
    matchmaker::MatchMaker, 
    random_number_generator::AbstractRNG,
    interaction_id::String,
    all_species::Vector{AbstractSpecies},
)
    throw(ErrorException(
        "`make_matches` not implemented for matchmaker $matchmaker and species $all_species."
        )
    )
end

function get_individual_ids_from_cohorts(
    species::AbstractSpecies, matchmaker::MatchMaker
)
    individuals = vcat([getfield(species, Symbol(cohort)) for cohort in matchmaker.cohorts]...)
    ids = [individual.id for individual in individuals]
    return ids
end