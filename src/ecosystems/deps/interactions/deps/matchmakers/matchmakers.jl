module MatchMakers

export Abstract, Matches, AllvsAll

include("abstract/abstract.jl")
using .Abstract: Abstract

include("deps/matches/matches.jl")
using .Matches: Matches

include("types/all_vs_all.jl")
using .AllvsAll: AllvsAll

end
