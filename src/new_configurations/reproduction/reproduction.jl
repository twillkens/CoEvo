module ReproductionConfigurations

export Roulette, Tournament, Disco

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("roulette/roulette.jl")
using .Roulette: Roulette

include("tournament/tournament.jl")
using .Tournament: Tournament

include("disco/disco.jl")
using .Disco: Disco

#include("map/map.jl")


end