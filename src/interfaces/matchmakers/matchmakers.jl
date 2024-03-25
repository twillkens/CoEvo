export make_matches, make_all_matches

using ..Abstract

function make_matches(
    matchmaker::MatchMaker, 
    interaction_id::String,
    species_1::AbstractSpecies,
    species_2::AbstractSpecies,
    state::State
)
    matchmaker = typeof(matchmaker)
    interaction_id = typeof(interaction_id)
    species_1 = typeof(species_1)
    species_2 = typeof(species_2)
    state = typeof(state)
    error("make_matches not implemented for $matchmaker, $interaction_id, $species_1, $species_2, $state")
end

function make_matches(
    matchmaker::MatchMaker,
    interaction_id::String,
    all_species::Vector{<:AbstractSpecies},
    state::State
)
    if length(all_species) != 2
        throw(ErrorException("Only two-entity interactions are supported for now."))
    end
    species_1 = all_species[1]
    species_2 = all_species[2]
    matches = make_matches(matchmaker, interaction_id, species_1, species_2, state)
    return matches
end

function make_all_matches(job_creator::JobCreator, ecosystem::Ecosystem, state::State)
    job_creator = typeof(job_creator)
    ecosystem = typeof(ecosystem)
    error("make_all_matches not implemented for $job_creator, $ecosystem")
end