module States

export Basic #, IslandModel

include("basic/basic.jl")
using .Basic: Basic

#include("island_model/island_model.jl")
#using .IslandModel: IslandModel

end