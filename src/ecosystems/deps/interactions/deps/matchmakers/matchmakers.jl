module MatchMakers

export Abstract, Matches, Interfaces, AllvsAll, Methods

include("abstract/abstract.jl")
using .Abstract: Abstract

include("deps/matches/matches.jl")
using .Matches: Matches

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/all_vs_all.jl")
using .AllvsAll: AllvsAll

include("methods/methods.jl")
using .Methods: Methods

end
