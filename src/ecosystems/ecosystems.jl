module Ecosystems

export CoevolutionaryEcosystemCfg

include("args/observations/observations.jl")
include("args/species/species.jl")
include("args/jobs/jobs.jl")
include("args/reporters/reporters.jl")
include("args/archivers/archivers.jl")

include("types/coevolutionary/coevolutionary.jl")

end