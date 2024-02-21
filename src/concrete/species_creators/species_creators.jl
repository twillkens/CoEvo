module SpeciesCreators

export Basic, Redisco, HillClimber #, AdaptiveArchive# , Modes

include("basic/basic.jl")
using .Basic: Basic

#include("archive/archive.jl")
#using .Archive: Archive

include("redisco/redisco.jl")
using .Redisco: Redisco

include("hillclimber/hillclimber.jl")
using .HillClimber: HillClimber

include("dodo/dodo.jl")
using .Dodo: Dodo

#include("adaptive_archive/adaptive_archive.jl")
#using .AdaptiveArchive: AdaptiveArchive

#include("modes/modes.jl")
#using .Modes: Modes

end
