module Ecosystems

export BasicEcosystemCreator

include("abstract/abstract.jl")

using .Abstract

include("utilities/utilities.jl")

using .Utilities

include("deps/reporters/reporters.jl")
include("deps/species/species.jl")
include("deps/jobs/jobs.jl")
include("deps/archivers/archivers.jl")

include("types/basic.jl")

end