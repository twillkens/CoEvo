module Performers

export Basic, Cache, Modes

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

include("cache/cache.jl")
using .Cache: Cache

include("modes/modes.jl")
using .Modes: Modes

# include("modes/modes_func.jl")
# using .ModesFunc: ModesFunc

end