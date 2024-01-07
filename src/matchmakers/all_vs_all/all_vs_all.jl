module AllVersusAll

export AllVersusAllMatchMaker, make_matches

import ..MatchMakers: make_matches

using Random: AbstractRNG
using ...Species: AbstractSpecies, get_individuals_to_perform
using ...Species.Basic: BasicSpecies
using ...Species.Modes: ModesSpecies
using ...Matches.Basic: BasicMatch
using ..MatchMakers: MatchMaker, get_individual_ids_from_cohorts

Base.@kwdef struct AllVersusAllMatchMaker <: MatchMaker 
    cohorts::Vector{String} = ["population", "children"]
end


function make_matches(
    matchmaker::AllVersusAllMatchMaker, 
    interaction_id::String, 
    species_1::BasicSpecies, 
    species_2::BasicSpecies
)
    ids_1 = get_individual_ids_from_cohorts(species_1, matchmaker)
    ids_2 = get_individual_ids_from_cohorts(species_2, matchmaker)
    match_ids = vec(collect(Iterators.product(ids_1, ids_2)))
    matches = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids]
    return matches
end

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
    matches = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids]
    #println("n_matches = $(length(matches))")
    return matches
end

#function make_matches(
#    ::AllVersusAllMatchMaker, 
#    interaction_id::String, 
#    species_1::ModesSpecies, 
#    species_2::ModesSpecies
#)
#    modes_ids_1 = [individual.id for individual in species_1.modes_individuals ]
#    normal_ids_2 = [individual.id for individual in species_2.normal_individuals]
#    match_ids_1 = vec(collect(Iterators.product(modes_ids_1, normal_ids_2)))
#    matches_1 = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids_1]  
#
#    normal_ids_1 = [individual.id for individual in species_1.normal_individuals]
#    modes_ids_2 = [individual.id for individual in species_2.modes_individuals]
#    match_ids_2 = vec(collect(Iterators.product(normal_ids_1, modes_ids_2)))
#    matches_2 = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids_2]
#
#    matches = vcat(matches_1, matches_2)
#    #println("matches: $matches")
#    return matches
#end

function make_matches(
    matchmaker::AllVersusAllMatchMaker, 
    ::AbstractRNG,
    interaction_id::String, 
    species_1::AbstractSpecies,
    species_2::AbstractSpecies
)
    matches = make_matches(matchmaker, interaction_id, species_1, species_2)
    #println("number of matches: $(length(matches))")
    #println("length of species_1: $(length(get_individuals_to_perform(species_1)))")
    return matches
end


end