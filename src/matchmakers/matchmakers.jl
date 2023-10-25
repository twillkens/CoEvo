module MatchMakers

export AllvsAll

using Random: AbstractRNG
using ..Matches: Match
using ..Species: AbstractSpecies

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("all_vs_all/all_vs_all.jl")
using .AllvsAll: AllvsAll

end
