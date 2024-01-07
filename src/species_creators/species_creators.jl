module SpeciesCreators

export Basic, Archive #, AdaptiveArchive# , Modes

using Random: AbstractRNG
using ..Species: AbstractSpecies
using ..Counters: Counter
using ..Evaluators: Evaluation
using ..Individuals: Individual

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

include("archive/archive.jl")
using .Archive: Archive

#include("adaptive_archive/adaptive_archive.jl")
#using .AdaptiveArchive: AdaptiveArchive

#include("modes/modes.jl")
#using .Modes: Modes

end
