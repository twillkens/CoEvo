module FunctionGraphs

export Basic, Linearized

include("basic/basic.jl")
using .Basic: Basic

include("linearized/linearized.jl")
using .Linearized: Linearized

end