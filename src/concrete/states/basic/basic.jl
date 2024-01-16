module Basic

export BasicEvolutionaryState 

import ....Interfaces: update_ecosystem!, evolve!, create_ecosystem, archive!
using ....Abstract
using ....Interfaces
using StableRNGs: StableRNG

include("state.jl")

include("create.jl")

include("evolve.jl")

end