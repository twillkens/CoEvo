module Ecosystems

export CoevolutionaryEcosystemConfiguration

include("deps/observations/observations.jl")
include("deps/species/species.jl")
include("deps/jobs/jobs.jl")
include("deps/reporters/reporters.jl")
include("deps/archivers/archivers.jl")

include("types/coevolutionary/coevolutionary.jl")

end