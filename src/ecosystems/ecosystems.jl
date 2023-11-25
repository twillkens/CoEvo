module Ecosystems

export Basic

import ..Evaluators: evaluate

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

end