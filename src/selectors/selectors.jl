module Selectors

export Identity, FitnessProportionate, Tournament

using Random: AbstractRNG
using DataStructures: OrderedDict
using ..Individuals: Individual
using ..Species: AbstractSpecies
using ..Evaluators: Evaluation

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("identity/identity.jl")
using .Identity: Identity

include("fitness_proportionate/fitness_proportionate.jl")
using .FitnessProportionate: FitnessProportionate

include("tournament/tournament.jl")
using .Tournament: Tournament

end 
