module Species

export Basic, Modes, AdaptiveArchive, Temp

import ..Individuals: get_individuals

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

#include("adaptive_archive/adaptive_archive.jl")
#using .AdaptiveArchive: AdaptiveArchive

include("modes/modes.jl")
using .Modes: Modes

include("prune/prune.jl")
using .Prune: Prune

end
