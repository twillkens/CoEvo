module AllVersusAll

import ..MatchMakers: make_matches

using Random: AbstractRNG
using ...Species: AbstractSpecies
using ...Matches.Basic: BasicMatch
using ..MatchMakers: MatchMaker, get_individual_ids_from_cohorts

Base.@kwdef struct AllVersusAllMatchMaker <: MatchMaker 
    cohorts::Vector{String} = ["population", "children"]
end

function make_matches(
    matchmaker::AllVersusAllMatchMaker, 
    interaction_id::String, 
    species_1::AbstractSpecies, 
    species_2::AbstractSpecies
)
    ids_1 = get_individual_ids_from_cohorts(species_1, matchmaker)
    ids_2 = get_individual_ids_from_cohorts(species_2, matchmaker)
    match_ids = vec(collect(Iterators.product(ids_1, ids_2)))
    matches = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids]
    return matches
end

function make_matches(
    matchmaker::AllVersusAllMatchMaker,
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