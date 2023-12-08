
import CoEvo.MatchMakers: make_matches
using CoEvo.Matches.Basic: BasicMatch

function make_matches(
    ::AllVersusAllMatchMaker, 
    interaction_id::String, 
    species_1::ModesSpecies, 
    species_2::ModesSpecies
)
    modes_ids_1 = [individual.id for individual in species_1.modes_individuals ]
    normal_ids_2 = [individual.id for individual in species_2.normal_individuals]
    match_ids_1 = vec(collect(Iterators.product(modes_ids_1, normal_ids_2)))
    matches_1 = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids_1]  

    normal_ids_1 = [individual.id for individual in species_1.normal_individuals]
    modes_ids_2 = [individual.id for individual in species_2.modes_individuals]
    match_ids_2 = vec(collect(Iterators.product(normal_ids_1, modes_ids_2)))
    matches_2 = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids_2]

    matches = vcat(matches_1, matches_2)
    #println("matches: $matches")
    return matches
end