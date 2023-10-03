module Types

export IdentitySelector, FitnessProportionateSelector #, TournamentSelector

include("identity.jl")
using .Identity: IdentitySelector

include("fitness_proportionate.jl")
using .FitnessProportionate: FitnessProportionateSelector

include("tournament.jl")
using .Tournament: TournamentSelector


end