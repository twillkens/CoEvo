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
    species_id_1::String,
    species_id_2::String,
    ids_1::Vector{Int},
    ids_2::Vector{Int},
)
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
    match_ids = vec(collect(Iterators.product(ids_1, ids_2)))
    matches = [
        BasicMatch(interaction_id, (id_1, id_2), (species_id_1, species_id_2)) 
        for (id_1, id_2) in match_ids
    ]
    #println("n_matches = $(length(matches))")
    return matches
end
using ...Species.Archive: ArchiveSpecies

function make_matches(
    matchmaker::AllVersusAllMatchMaker, 
    interaction_id::String,
    species_1::ArchiveSpecies,
    species_2::ArchiveSpecies
)
    pop_ids_1 = [individual.id for individual in species_1.population]
    pop_ids_2 = [individual.id for individual in species_2.population]
    archive_ids_1 = [individual.id for individual in species_1.active_archive_individuals]
    archive_ids_2 = [individual.id for individual in species_2.active_archive_individuals]
    pop_matches = make_matches(
        matchmaker, interaction_id, species_1.id, species_2.id, pop_ids_1, pop_ids_2
    )
    learner_evaluator_matches_1 = make_matches(
        matchmaker, interaction_id, species_1.id, species_2.id, pop_ids_1, archive_ids_2
    )
    learner_evaluator_matches_2 = make_matches(
        matchmaker, interaction_id, species_1.id, species_2.id, archive_ids_1, pop_ids_2
    )
    matches = [pop_matches ; learner_evaluator_matches_1 ; learner_evaluator_matches_2]
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