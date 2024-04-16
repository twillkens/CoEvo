module Recombiners

export Clone, Identity, NPointCrossover

include("clone/clone.jl")
using .Clone: Clone

include("identity/identity.jl")
using .Identity: Identity

include("n_point_crossover/n_point_crossover.jl")
using .NPointCrossover: NPointCrossover

end
