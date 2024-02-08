module Selectors

export Identity, FitnessProportionate, Tournament

include("selections/selections.jl")
using .Selections: Selections

include("identity/identity.jl")
using .Identity: Identity

include("fitness_proportionate/fitness_proportionate.jl")
using .FitnessProportionate: FitnessProportionate

include("tournament/tournament.jl")
using .Tournament: Tournament

end 
