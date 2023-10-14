module Methods

export Basic, Modi

include("basic.jl")
using .Basic: Basic

include("modi.jl")
using .Modi: Modi

end