module AllvsAll

using ..MatchMakers.Abstract: MatchMaker
using ..Matches.Basic: BasicMatch
using ....Species.Abstract: AbstractSpecies
using Random: AbstractRNG

import ..MatchMakers.Interfaces: make_matches

"""
    AllvsAllMatchMaker <: MatchMaker

Struct for specifying the matchmaking strategy between two species. 
Supports two types:
- `:plus`: Matches all combinations of individuals, including both current population and children.
- `:comma`: Matches only current population or children, depending on which is non-empty.

# Fields
- `type::Symbol`: Specifies the type of matchmaking to be done (`:plus` or `:comma`).
"""
Base.@kwdef struct AllvsAllMatchMaker <: MatchMaker 
    cohorts::Vector{Symbol} = [:population, :children]
end

"""
    (mm::AllvsAllMatchMaker)(sp1::Species, sp2::Species) -> Vector{Tuple{Int, Int}}

Matchmaking function to create pairs of individuals between two species based on the type of `AllvsAllMatchMaker`.

# Arguments
- `mm::AllvsAllMatchMaker`: Matchmaking configuration.
- `sp1::Species`: First species for matchmaking.
- `sp2::Species`: Second species for matchmaking.

# Returns
- A vector of pairs (Tuples), each pair represents a match between an individual from `sp1` and `sp2`.

# Errors
- Throws an error if an invalid type is set in `AllvsAllMatchMaker`.
"""

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
    species_ids::Vector{String}
)
    if length(species_ids) != 2
        throw(ErrorException("Only two-entity interactions are supported for now."))
    end
    species_1 = find_species_by_id(species_ids[1], all_species)
    species_2 = find_species_by_id(species_ids[2], all_species)
    matches = make_matches(matchmaker, interaction_id, species_1, species_2)
    return matches
end


end