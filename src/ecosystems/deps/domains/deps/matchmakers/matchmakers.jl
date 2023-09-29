module MatchMakers

export Abstract, Matches, AllVsAll

include("abstract/abstract.jl")
using .Abstract: Abstract

include("deps/matches/matches.jl")
using .Matches: Matches

include("types/all_vs_all.jl")
using .AllVsAll: AllVsAll

end
