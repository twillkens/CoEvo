module OneVersusAll

export OneVersusAllMatchMaker

import ....Interfaces: make_matches
using ....Abstract
using ....Interfaces
using ...Matches.Basic: BasicMatch

Base.@kwdef struct OneVersusAllMatchMaker <: MatchMaker end


function make_matches(
    matchmaker::OneVersusAllMatchMaker, 
    interaction_id::String, 
    individual::Individual,
    species_2::AbstractSpecies
)
    id_1 = individual.id
    ids_2 = [individual.id for individual in get_individuals_to_perform(species_2)]
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