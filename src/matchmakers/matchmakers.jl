module MatchMakers

export Abstract, Interfaces, AllvsAll

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("all_vs_all/all_vs_all.jl")
using .AllvsAll: AllvsAll

end
