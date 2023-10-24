module Selectors

export Abstract, Interfaces, Identity, FitnessProportionate, Tournament

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("identity/identity.jl")
using .Identity: Identity

include("fitness_proportionate/fitness_proportionate.jl")
using .FitnessProportionate: FitnessProportionate

include("tournament/tournament.jl")
using .Tournament: Tournament

end 
