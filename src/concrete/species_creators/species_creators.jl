module SpeciesCreators

export Basic, Archive #, AdaptiveArchive# , Modes

include("basic/basic.jl")
using .Basic: Basic

include("archive/archive.jl")
using .Archive: Archive

include("distinguisher/distinguisher.jl")
using .Distinguisher: Distinguisher

#include("adaptive_archive/adaptive_archive.jl")
#using .AdaptiveArchive: AdaptiveArchive

#include("modes/modes.jl")
#using .Modes: Modes

end
