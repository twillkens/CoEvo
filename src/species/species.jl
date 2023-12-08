module Species

export Basic, Modes

import ..Individuals: get_individuals

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

include("modes/modes.jl")
using .Modes: Modes

end
