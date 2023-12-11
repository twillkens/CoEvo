export make_matches, get_individual_ids_from_cohorts

function make_matches(
    matchmaker::MatchMaker, 
    random_number_generator::AbstractRNG,
    interaction_id::String,
    species_1::AbstractSpecies,
    species_2::AbstractSpecies
)
    species_1_type = typeof(species_1)
    species_2_type = typeof(species_2)
    throw(ErrorException(
        "`make_matches` not implemented for matchmaker $matchmaker, $species_1_type, $species_2_type."
        )
    )
end

function make_matches(
    matchmaker::MatchMaker,
    rng::AbstractRNG,
    interaction_id::String,
    all_species::Vector{<:AbstractSpecies},
)
    if length(all_species) != 2
        throw(ErrorException("Only two-entity interactions are supported for now."))
    end
    species_1 = all_species[1]
    species_2 = all_species[2]
    matches = make_matches(matchmaker, rng, interaction_id, species_1, species_2)
    return matches
end

function get_individual_ids_from_cohorts(
    species::AbstractSpecies, matchmaker::MatchMaker
)
    individuals = vcat([getfield(species, Symbol(cohort)) for cohort in matchmaker.cohorts]...)
    ids = [individual.id for individual in individuals]
    return ids
end
