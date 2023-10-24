module Observers

export Basic, Null

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

include("null/null.jl")
using .Null: Null

end