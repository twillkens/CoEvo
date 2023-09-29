module AllvsAll

using ..Matches

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
    type::Symbol = :plus
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
function make_matches(
    matchmaker::AllvsAllMatchMaker, sp1::AbstractSpecies, sp2::AbstractSpecies
)
    if matchmaker.type == :comma
        ids1 = length(s1.children) == 0 ? collect(keys(sp1.pop)) : collect(keys(sp1.children))
        ids2 = length(s2.children) == 0 ? collect(keys(sp2.pop)) : collect(keys(sp2.children))
    elseif matchmaker.type == :plus
        ids1 = [collect(keys(sp1.pop)); collect(keys(sp1.children))]
        ids2 = [collect(keys(sp2.pop)); collect(keys(sp2.children))]
    else
        error("Invalid AllvsAllMatchMaker type: $(matchmaker.type)")
    end
    match_ids = vec(collect(Iterators.product(ids1, ids2)))
    matches = [
        BasicMatch(domain.id, [id1, id2]) for (id1, id2) in match_ids
    ]
end

end