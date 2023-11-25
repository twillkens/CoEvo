module OneVersusAll

export OneVersusAllMatchMaker

import ..MatchMakers: make_matches

using Random: AbstractRNG
using ...Individuals: Individual
using ...Species: AbstractSpecies
using ...Matches.Basic: BasicMatch
using ..MatchMakers: MatchMaker, get_individual_ids_from_cohorts

Base.@kwdef struct OneVersusAllMatchMaker <: MatchMaker 
    cohorts::Vector{String} = ["population", "children"]
end


function make_matches(
    matchmaker::OneVersusAllMatchMaker, 
    interaction_id::String, 
    individual::Individual,
    species_2::AbstractSpecies
)
    id_1 = individual.id
    ids_2 = get_individual_ids_from_cohorts(species_2, matchmaker)
    matches = [BasicMatch(interaction_id, [id_1, id_2]) for id_2 in ids_2]
    return matches
end


function make_matches(
    matchmaker::OneVersusAllMatchMaker,
    ::AbstractRNG,
    interaction_id::String,
    all_species::Vector{<:AbstractSpecies},
)
    if length(all_species) != 2
        throw(ErrorException("Only two-entity interactions are supported for now."))
    end
    species_1 = all_species[1]
    species_2 = all_species[2]
    matches = make_matches(matchmaker, interaction_id, species_1, species_2)
    return matches
end

end