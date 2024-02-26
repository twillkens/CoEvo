module ECAOptimized

using Distributions
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
    current_state::Vector{Int}
    next_state::Vector{Int}
    n_timesteps::Int
    current_timestep::Int
    last_uniform_state::Int  # -1 for no uniform, 0 for all 0s, 1 for all 1s
end

Base.@kwdef struct ElementaryCellularAutomataEnvironmentCreator{D} <: EnvironmentCreator{D}
    domain::D = DensityClassificationDomain("Covers")
    n_timesteps::Int = 320
    use_poisson::Bool = false
end

function choose_poisson(n::Float64)
    poisson_dist = Poisson(n)
    M = rand(poisson_dist)
    return M
end

function create_environment(
    environment_creator::ElementaryCellularAutomataEnvironmentCreator,
    rule::BasicVectorPhenotype,
    initial_condition::BasicVectorPhenotype,
)
    n_timesteps = environment_creator.use_poisson ? choose_poisson(environment_creator.n_timesteps) : environment_creator.n_timesteps
    r = Int((log2(length(rule.values)) - 1) / 2)
    environment = ElementaryCellularAutomataEnvironment(
        environment_creator.domain,
        rule,
        r,
        initial_condition,
        copy(initial_condition.values),  # Current state initialized to initial condition
        similar(initial_condition.values),  # Next state initialized as a similar structure
        n_timesteps,
        1,
        -1  # Initial last uniform state set to indicate no uniform state yet
    )
    return environment
end

function is_active(environment::ElementaryCellularAutomataEnvironment)
    return environment.current_timestep <= environment.n_timesteps
end

function step!(environment::ElementaryCellularAutomataEnvironment)
    fill!(environment.next_state, 0)  # Reset next_state before use
    rule = environment.rule.values
    r = environment.r
    for i in 1:length(environment.current_state)
        index = 0
        for j = -r:r
            neighbor_index = mod(i + j - 1, length(environment.current_state)) + 1
            index = (index << 1) + environment.current_state[neighbor_index]
        end
        # Directly map index to rule vector, adjusting for 1-based indexing
        rule_index = index + 1
        if rule_index < 1 || rule_index > length(rule)
            throw(BoundsError(rule, rule_index))
        end
        environment.next_state[i] = rule[rule_index]
    end

    #if all(x -> x == environment.next_state[1], environment.next_state)
    #    if environment.last_uniform_state == environment.next_state[1] || environment.current_timestep == 1
    #        environment.n_timesteps = environment.current_timestep
    #    end
    #    environment.last_uniform_state = environment.next_state[1]
    #else
    #    environment.last_uniform_state = -1
    #end

    environment.current_state, environment.next_state = environment.next_state, environment.current_state
    environment.current_timestep += 1
end


function get_phenotypes(environment::ElementaryCellularAutomataEnvironment)
    return [environment.rule, environment.initial_condition]
end

function get_majority_value(values::Vector{Int})
    sum(values) > length(values) / 2 ? 1 : 0
end

function get_outcome_set(environment::ElementaryCellularAutomataEnvironment)
    initial_condition = environment.initial_condition.values
    final_state = environment.current_state
    maj_value = get_majority_value(initial_condition)
    # Check if the final state has "relaxed" to a uniform state matching the majority value
    if all(x -> x == maj_value, final_state)
        return [1.0, 0.0]  # The system has relaxed to the expected majority state
    else
        return [0.0, 1.0]  # The system has not relaxed to the expected majority state
    end
end

end  # End of module

