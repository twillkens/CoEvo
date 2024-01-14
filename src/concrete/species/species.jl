module Species

export Basic, Archive #, Prune

include("basic/basic.jl")
using .Basic: Basic

#include("prune/prune.jl")
#using .Prune: Prune

include("archive/archive.jl")
using .Archive: Archive

end
