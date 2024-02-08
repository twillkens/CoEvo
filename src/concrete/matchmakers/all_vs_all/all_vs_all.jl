module AllVersusAll

export AllVersusAllMatchMaker, make_matches

import ....Interfaces: make_matches

using ....Abstract
using ....Interfaces
using ...Matches.Basic: BasicMatch

Base.@kwdef struct AllVersusAllMatchMaker <: MatchMaker end

function validate_ids(ids_1::Vector{Int}, ids_2::Vector{Int})
    if length(ids_1) != length(Set(ids_1))
        error("ids_1 contains duplicates")
    end
    if length(ids_2) != length(Set(ids_2))
        error("ids_2 contains duplicates")
    end
    for id in ids_1
        if id in ids_2
            println("ids_1 = $ids_1")
            println("ids_2 = $ids_2")
            error("individual with id $id is in both species")
        end
    end
end

function make_matches(
    ::AllVersusAllMatchMaker, 
    interaction_id::String,
    ids_1::Vector{Int},
    ids_2::Vector{Int},
    species_id_1::String = "A",
    species_id_2::String = "B",
)
    validate_ids(ids_1, ids_2)
    match_ids = vec(collect(Iterators.product(ids_1, ids_2)))
    matches = [
        BasicMatch(interaction_id, (id_1, id_2), (species_id_1, species_id_2)) 
        for (id_1, id_2) in match_ids
    ]
    return matches
end

function make_matches(
    matchmaker::AllVersusAllMatchMaker, 
    interaction_id::String,
    individuals_1::Vector{<:Individual},
    individuals_2::Vector{<:Individual},
    species_id_1::String = "A",
    species_id_2::String = "B",
)
    ids_1 = [individual.id for individual in individuals_1]
    ids_2 = [individual.id for individual in individuals_2]
    matches = make_matches(
        matchmaker, interaction_id, ids_1, ids_2, species_id_1, species_id_2
    )
    return matches
end

function make_matches(
    matchmaker::AllVersusAllMatchMaker, 
    interaction_id::String,
    species_1::AbstractSpecies,
    species_2::AbstractSpecies
)
    individuals_1 = species_1.population
    individuals_2 = species_2.population
    matches = make_matches(matchmaker, interaction_id, individuals_1, individuals_2)
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