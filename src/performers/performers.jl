module Performers

export Basic, Cache

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

include("cache/cache.jl")
using .Cache: Cache

# include("modes/modes_func.jl")
# using .ModesFunc: ModesFunc

end