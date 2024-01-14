module RandomSample

import ....Interfaces: make_matches

using Random: AbstractRNG
using StatsBase: sample
using ....Abstract
using ....Interfaces
using ...Matches.Basic: BasicMatch

Base.@kwdef struct RandomSampleMatchMaker <: MatchMaker 
    n_sample_1::Int = 10
    n_sample_2::Int = 10
    replace_1::Bool = false
    replace_2::Bool = false
end

function make_matches(
    matchmaker::RandomSampleMatchMaker, 
    rng::AbstractRNG,
    interaction_id::String, 
    species_1::AbstractSpecies,
    species_2::AbstractSpecies
)
    ids_1 = [individual.id for individual in get_individuals(species_1)]
    ids_2 = [individual.id for individual in get_individuals(species_2)]
    sampled_ids_1 = sample(rng, ids_1, matchmaker.n_sample_1, replace = matchmaker.replace_1)
    sampled_ids_2 = sample(rng, ids_2, matchmaker.n_sample_2, replace = matchmaker.replace_2)
    match_ids = vec(collect(Iterators.product(sampled_ids_1, sampled_ids_2)))
    matches = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids]
    return matches
end

end