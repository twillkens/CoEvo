module Species

export Basic

import ..Individuals: get_individuals

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

end
