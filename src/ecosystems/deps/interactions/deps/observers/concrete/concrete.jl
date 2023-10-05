module Concrete

export Basic, Null

include("basic/basic.jl")
using .Basic: Basic

include("null/null.jl")
using .Null: Null

end