module AllvsAll

import ..MatchMakers: make_matches

using Random: AbstractRNG
using ...Species: AbstractSpecies
using ...Matches.Basic: BasicMatch
using ..MatchMakers: MatchMaker

Base.@kwdef struct AllvsAllMatchMaker <: MatchMaker 
    cohorts::Vector{Symbol} = [:population, :children]
end

function get_individual_ids_from_cohorts(
    species::AbstractSpecies, matchmaker::AllvsAllMatchMaker
)
    individuals = vcat([getfield(species, cohort) for cohort in matchmaker.cohorts]...)
    ids = [individual.id for individual in individuals]
    return ids
end

function make_matches(
    matchmaker::AllvsAllMatchMaker, 
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

function find_species_by_id(species_id::String, species_list::Vector{<:AbstractSpecies})
    index = findfirst(s -> s.id == species_id, species_list)
    if index === nothing
        throw(ErrorException("Species with id $species_id not found."))
    end
    return species_list[index]
end

function make_matches(
    matchmaker::AllvsAllMatchMaker,
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