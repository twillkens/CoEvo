module AdaptiveArchive

export AdaptiveArchiveMatchMaker

import ...MatchMakers: make_matches

using Random: AbstractRNG
using StatsBase: sample
using ...Species: AbstractSpecies
using ...Matches.Basic: BasicMatch
using ...Individuals: get_individuals, Individual
using ...Species.Basic: BasicSpecies
using ...Species.AdaptiveArchive: AdaptiveArchiveSpecies
using ...MatchMakers: MatchMaker

Base.@kwdef struct AdaptiveArchiveMatchMaker{M <: MatchMaker} <: MatchMaker 
    basic_matchmaker::M
    n_sample::Int = 10
end

function make_matches(
    rng::AbstractRNG,
    n_sample::Int,
    interaction_id::String,
    archive::Vector{<:Individual},
    others::Vector{<:Individual};
    reverse_ids::Bool = false
)
    archive_ids = [individual.id for individual in archive]
    n_sample = min(n_sample, length(archive_ids))
    sampled_archive_ids = sample(rng, archive_ids, n_sample, replace = false)
    other_ids = [individual.id for individual in others]
    match_id_tuples = vec(collect(Iterators.product(sampled_archive_ids, other_ids)))
    if reverse_ids
        all_match_ids = [[id_2, id_1] for (id_1, id_2) in match_id_tuples]
    else
        all_match_ids = [[id_1, id_2] for (id_1, id_2) in match_id_tuples]
    end
    matches = [BasicMatch(interaction_id, match_ids) for match_ids in all_match_ids]
    #matches = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids]
    return matches
end


function make_matches(
    matchmaker::AdaptiveArchiveMatchMaker, 
    rng::AbstractRNG,
    interaction_id::String, 
    species_1::AdaptiveArchiveSpecies,
    species_2::AdaptiveArchiveSpecies
)
    basic_matchmaker = matchmaker.basic_matchmaker
    basic_species_1 = species_1.basic_species
    basic_species_2 = species_2.basic_species
    basic_matches = make_matches(
        basic_matchmaker, rng, interaction_id, basic_species_1, basic_species_2
    )
    adaptive_matches_1 = make_matches(
        rng, 
        matchmaker.n_sample, 
        interaction_id, 
        get_individuals(species_1.archive, species_1.active_ids),
        get_individuals(basic_species_2);
        reverse_ids = false
    )
    adaptive_matches_2 = make_matches(
        rng, 
        matchmaker.n_sample, 
        interaction_id, 
        get_individuals(species_2.archive, species_2.active_ids),
        get_individuals(basic_species_1);
        reverse_ids = true
    )
    matches = [basic_matches ; adaptive_matches_1 ; adaptive_matches_2]
    return matches
end

end