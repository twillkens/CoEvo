module Species

export Basic

include("abstract/abstract.jl")

include("basic/basic.jl")
using .Basic: Basic

end
