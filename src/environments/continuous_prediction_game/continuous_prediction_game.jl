module ContinuousPredictionGame

import ..Environments: get_outcome_set, step!, is_active, create_environment, get_phenotypes

using ...Domains: Domain, measure
using ...Phenotypes: Phenotype, act!, reset!
using ...Domains.PredictionGame: PredictionGameDomain
using ..Environments: Environment, EnvironmentCreator

include("environment.jl")

include("step.jl")

include("outcome_sets.jl")

include("observers.jl")

end