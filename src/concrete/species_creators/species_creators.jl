module SpeciesCreators

export Basic, Redisco, HillClimber, DodoLearner, DodoTest, SpreadDodo, NewDodo #, AdaptiveArchive# , Modes

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

include("dodo_learner/dodo_learner.jl")
using .DodoLearner: DodoLearner

include("dodo_test/dodo_test.jl")
using .DodoTest: DodoTest

include("spread_dodo/spread_dodo.jl")
using .SpreadDodo: SpreadDodo

include("new_dodo/new_dodo.jl")
using .NewDodo: NewDodo

#include("adaptive_archive/adaptive_archive.jl")
#using .AdaptiveArchive: AdaptiveArchive

#include("modes/modes.jl")
#using .Modes: Modes

end
