module Stateless

export StatelessEnvironment, StatelessEnvironmentCreator

import ....Interfaces: create_environment, is_active, get_phenotypes, get_outcome_set

using ....Abstract: Environment, EnvironmentCreator, Domain, Phenotype
using ...Domains.NumbersGame: NumbersGameDomain
using ...Domains.SymbolicRegression: SymbolicRegressionDomain
using ....Interfaces: measure, act!, reset!

struct StatelessEnvironment{D, P1 <: Phenotype, P2 <: Phenotype} <: Environment{D}
    domain::D
    entity_1::P1
    entity_2::P2
end

Base.@kwdef struct StatelessEnvironmentCreator{D} <: EnvironmentCreator{D}
    domain::D
end

function create_environment(
    environment_creator::StatelessEnvironmentCreator{D}, 
    phenotype_1::Phenotype, 
    phenotype_2::Phenotype, 
) where {D <: Domain}
    environment = StatelessEnvironment(environment_creator.domain, phenotype_1, phenotype_2)
    return environment
end

function is_active(::StatelessEnvironment)
    return false
end

function get_phenotypes(environment::StatelessEnvironment)
    return [environment.entity_1, environment.entity_2]
end

function get_outcome_set(
    environment::StatelessEnvironment{D, <:Phenotype, <:Phenotype}
) where {D <: NumbersGameDomain}
    phenotype_A, phenotype_B = environment.entity_1, environment.entity_2
    output_A, output_B = act!(phenotype_A), act!(phenotype_B)
    outcome_set = measure(environment.domain, output_A, output_B)
    return outcome_set
end

function get_outcome_set(
    environment::StatelessEnvironment{D, <:Phenotype}
) where {D <: SymbolicRegressionDomain}
    subject, test = environment.entity_1, environment.entity_2
    x_value = act!(test)
    y = environment.domain.target_function(x_value[1])
    y_hat = act!(subject, x_value)
    outcome_set = measure(environment.domain, y, y_hat)
    return outcome_set
end

using ...Phenotypes.Vectors: BasicVectorPhenotype

function create_environment(environment_creator::StatelessEnvironmentCreator, v1::Vector, v2::Vector)
    phenotype_1 = BasicVectorPhenotype(1, v1)
    phenotype_2 = BasicVectorPhenotype(2, v2)
    environment = create_environment(environment_creator, phenotype_1, phenotype_2)
    return environment
end

end