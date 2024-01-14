module Ecosystems

export Null, Simple

include("null/null.jl")
using .Null: Null

include("simple/simple.jl")
using .Simple: Simple

end