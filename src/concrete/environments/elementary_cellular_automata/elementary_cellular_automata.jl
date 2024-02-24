
module ElementaryCellularAutomata

export ElementaryCellularAutomataEnvironment, ElementaryCellularAutomataEnvironmentCreator

import ....Interfaces: create_environment, is_active, get_phenotypes, get_outcome_set, step!

using ....Abstract: Environment, EnvironmentCreator, Domain, Phenotype
using ...Domains.DensityClassification: DensityClassificationDomain
using ...Phenotypes.Vectors: BasicVectorPhenotype
using ....Interfaces: measure, act!, reset!
using Distributions

mutable struct ElementaryCellularAutomataEnvironment{
    D, R <: BasicVectorPhenotype, IC <: BasicVectorPhenotype
} <: Environment{D}
    domain::D
    rule::R
    r::Int
    initial_condition::IC
    states::Matrix{Int}
    n_timesteps::Int
    current_timestep::Int
end

Base.@kwdef struct ElementaryCellularAutomataEnvironmentCreator{D} <: EnvironmentCreator{D}
    domain::D = DensityClassificationDomain("Covers")
    n_timesteps::Int = 320
    use_poisson::Bool = false
end

function choose_poisson(n::Float64)
    # Create a Poisson distribution with mean n
    poisson_dist = Poisson(n)
    # Sample an integer M from the Poisson distribution
    M = rand(poisson_dist)
    return M
end

function create_environment(
    environment_creator::ElementaryCellularAutomataEnvironmentCreator{D}, 
    rule::BasicVectorPhenotype, 
    initial_condition::BasicVectorPhenotype, 
) where {D <: Domain}
    matrix = zeros(Int, environment_creator.n_timesteps, length(initial_condition.values))
    matrix[1, :] = initial_condition.values
    r = Int((log2(length(rule.values)) - 1) / 2)
    n_timesteps = environment_creator.use_poisson ? 
        choose_poisson(environment_creator.n_timesteps) : environment_creator.n_timesteps
    environment = ElementaryCellularAutomataEnvironment(
        environment_creator.domain, rule, r, initial_condition, matrix, n_timesteps, 1
    )
    return environment
end

function create_environment(
    environment_creator::ElementaryCellularAutomataEnvironmentCreator,
    rule::Vector{Int},
    initial_condition::Vector{Int},
)
    rule_phenotype = BasicVectorPhenotype(1, rule)
    initial_condition_phenotype = BasicVectorPhenotype(2, initial_condition)
    return create_environment(environment_creator, rule_phenotype, initial_condition_phenotype)
end

function is_active(environment::ElementaryCellularAutomataEnvironment)
    #ct = environment.current_timestep
    #if ct > 1
    #    is_relaxed = all(x -> x == 0, environment.states[ct, :]) || all(x -> x == 1, environment.states[ct, :])
    #    last_two_the_same = environment.states[ct, :] == environment.states[ct - 1, :]
    #    if is_relaxed && last_two_the_same
    #        return false
    #    end
    #end
    return environment.current_timestep < environment.n_timesteps
end

function step!(environment::ElementaryCellularAutomataEnvironment)
    current_timestep = environment.current_timestep
    next_timestep = current_timestep + 1
    states = environment.states
    rule = environment.rule.values
    rule_length = length(rule)
    r = environment.r

    width = length(environment.initial_condition.values)
    for i in 1:width
        index = 0
        
        # Use modular arithmetic to handle wrapping
        for j = -r:r
            neighbor_index = mod(i + j - 1, width) + 1
            index = (index << 1) + states[current_timestep, neighbor_index]
        end
        
        # Apply the rule to determine the new state
        states[next_timestep, i] = rule[rule_length - index]
    end
    environment.current_timestep = next_timestep
end

function get_phenotypes(environment::ElementaryCellularAutomataEnvironment)
    return [environment.rule, environment.initial_condition]
end

function get_outcome_set(environment::ElementaryCellularAutomataEnvironment)
    outcome_set = measure(environment.domain, environment.states)
    return outcome_set
end

end
