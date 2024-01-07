module Species

export Basic, Modes, Archive

import ..Individuals: get_individuals

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

include("modes/modes.jl")
using .Modes: Modes

include("prune/prune.jl")
using .Prune: Prune

include("archive/archive.jl")
using .Archive: Archive

end
