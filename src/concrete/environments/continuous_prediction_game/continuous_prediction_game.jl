module ContinuousPredictionGame

export ContinuousPredictionGameEnvironmentCreator, ContinuousPredictionGameEnvironment

import ....Interfaces: get_outcome_set, step!, is_active, create_environment, get_phenotypes

using ....Abstract
using ....Interfaces
using ...Domains.PredictionGame: PredictionGameDomain

include("environment.jl")

include("step.jl")

include("outcome_sets.jl")

end