module States

export Primer, Basic #, IslandModel

include("primer/primer.jl")
using .Primer: Primer

include("basic/basic.jl")
using .Basic: Basic

#include("island_model/island_model.jl")
#using .IslandModel: IslandModel

end