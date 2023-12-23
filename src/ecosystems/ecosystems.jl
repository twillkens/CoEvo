module Ecosystems

#export Basic
export Simple
export Null

import ..Evaluators: evaluate

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("null/null.jl")
using .Null: Null

#include("basic/basic.jl")
#using .Basic: Basic

include("simple/simple.jl")
using .Simple: Simple

end