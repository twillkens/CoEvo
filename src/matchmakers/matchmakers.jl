module MatchMakers

export AllVersusAll, OneVersusAll

using Random: AbstractRNG
using ..Matches: Match
using ..Species: AbstractSpecies

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("all_vs_all/all_vs_all.jl")
using .AllVersusAll: AllVersusAll

include("one_vs_all/one_vs_all.jl")
using .OneVersusAll: OneVersusAll

end
