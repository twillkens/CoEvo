module AllVersusAll

export AllVersusAllMatchMaker, make_matches

import ....Interfaces: make_matches

using ....Abstract
using ....Interfaces
using ...Matches.Basic: BasicMatch

Base.@kwdef struct AllVersusAllMatchMaker <: MatchMaker end

function make_matches(
    ::AllVersusAllMatchMaker, 
    interaction_id::String,
    species_1::AbstractSpecies,
    species_2::AbstractSpecies
)
    ids_1 = [individual.id for individual in get_individuals_to_perform(species_1)]
    ids_2 = [individual.id for individual in get_individuals_to_perform(species_2)]
    ids_1 = collect(Set(ids_1))
    ids_2 = collect(Set(ids_2))
    match_ids = vec(collect(Iterators.product(ids_1, ids_2)))
    matches = [
        BasicMatch(interaction_id, (id_1, id_2), (species_1.id, species_2.id)) 
        for (id_1, id_2) in match_ids
    ]
    #println("n_matches = $(length(matches))")
    return matches
end

function make_matches(
    matchmaker::AllVersusAllMatchMaker, 
    ::AbstractRNG,
    interaction_id::String, 
    species_1::AbstractSpecies,
    species_2::AbstractSpecies
)
    matches = make_matches(matchmaker, interaction_id, species_1, species_2)
    println("number of matches: $(length(matches))")
    #println("length of species_1: $(length(get_individuals_to_perform(species_1)))")
    return matches
end


end