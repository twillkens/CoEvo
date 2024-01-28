module States

export Primer, Basic #Delphi #, IslandModel

include("primer/primer.jl")
using .Primer: Primer


include("basic/basic.jl")
using .Basic: Basic


#include("delphi/delphi.jl")
#using .Delphi: Delphi

#include("island_model/island_model.jl")
#using .IslandModel: IslandModel

end