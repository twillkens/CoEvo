module Mutations

export add_function, remove_function, swap_node, splice_function, inject_noise

include("add_function.jl")
include("remove_function.jl")
include("splice_function.jl")
include("swap_node.jl")
include("inject_noise.jl")

end