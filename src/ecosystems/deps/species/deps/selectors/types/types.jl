module Types

export IdentitySelector, FitnessProportionateSelector

include("identity.jl")
using .Identity: IdentitySelector

include("fitness_proportionate.jl")
using .FitnessProportionate: FitnessProportionateSelector
# include("tournament.jl")


end