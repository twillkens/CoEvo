module Stateless

import ..Environments: get_outcome_set, is_active, create_environment

using ...Phenotypes: Phenotype, act!, reset!
using ...Domains: Domain, measure
using ...Domains.SymbolicRegression: SymbolicRegressionDomain
using ...Domains.NumbersGame: NumbersGameDomain
using ..Environments: Environment, EnvironmentCreator

include("environment.jl")

include("outcome_sets.jl")

end