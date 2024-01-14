module Jobs

export Simple

include("simple/simple.jl")
using .Simple: Simple

end