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
    for id in ids_1
        if id in ids_2
            println("ids_1 = $ids_1")
            println("ids_2 = $ids_2")
            error("individual with id $id is in both species")
        end
    end
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
    interaction_id::String, 
    species::Vector{<:AbstractSpecies},
    ::State
)
    if length(species) != 2
        error("AllVersusAllMatchMaker requires exactly two species")
    end
    matches = make_matches(matchmaker, interaction_id, species[1], species[2])
    #println("number of matches: $(length(matches))")
    return matches
end


end