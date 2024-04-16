module Ecosystems

export Simple, QueMEU

include("simple/simple.jl")
using .Simple: Simple

include("quemeu/quemeu.jl")
using .QueMEU: QueMEU

end