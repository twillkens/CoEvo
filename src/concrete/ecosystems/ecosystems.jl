module Ecosystems

export Null, Simple, MaxSolve

include("null/null.jl")
using .Null: Null

include("simple/simple.jl")
using .Simple: Simple

include("maxsolve/maxsolve.jl")
using .MaxSolve: MaxSolve

end