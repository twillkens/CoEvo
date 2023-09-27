module Selectors

export IdentitySelector, FitnessProportionateSelector

include("abstract/abstract.jl")
using .Abstract

include("types/identity.jl")
include("types/fitness_proportionate.jl")
# include("types/tournament.jl")

end # end of Selectors module
