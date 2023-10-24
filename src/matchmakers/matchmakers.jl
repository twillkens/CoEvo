module MatchMakers

export AllvsAll

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("all_vs_all/all_vs_all.jl")
using .AllvsAll: AllvsAll

end
