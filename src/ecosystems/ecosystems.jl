module Ecosystems

export CoevolutionaryEcosystemConfiguration

include("args/observations/observations.jl")
include("args/species/species.jl")
include("args/jobs/jobs.jl")
include("args/reporters/reporters.jl")
include("args/archivers/archivers.jl")

include("types/coevolutionary/coevolutionary.jl")

using .Observations
using .SpeciesTypes
using .Jobs
using .Reporters
using .Archivers

end