module ElementaryCellularAutomataOptimized

using Distributions

# BasicVectorPhenotype placeholder definition (to be replaced with actual implementation)
struct BasicVectorPhenotype <: AbstractVector{Int}
    id::Int
    values::Vector{Int}
end

# Domain and Metric placeholder definitions
abstract type Domain end
abstract type Metric end

# Environment and EnvironmentCreator placeholder abstract types
abstract type Environment{D} where D<:Domain end
abstract type EnvironmentCreator{D} where D<:Domain end

# Placeholder for DensityClassificationDomain (to be replaced with actual implementation)
struct DensityClassificationDomain <: Domain
    name::String
end

mutable struct ElementaryCellularAutomataEnvironment{D, R <: BasicVectorPhenotype, IC <: BasicVectorPhenotype} <: Environment{D}
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
        initial_condition.values,  # Current state initialized to initial condition
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
        environment.next_state[i] = rule[end - index + 1]
    end

    if all(x -> x == environment.next_state[1], environment.next_state)
        if environment.last_uniform_state == environment.next_state[1] || environment.current_timestep == 1
            environment.n_timesteps = environment.current_timestep
        end
        environment.last_uniform_state = environment.next_state[1]
    else
        environment.last_uniform_state = -1
    end

    environment.current_state, environment.next_state = environment.next_state, environment.current_state
    environment.current_timestep += 1
end

function get_phenotypes(environment::ElementaryCellularAutomataEnvironment)
    return [environment.rule, environment.initial_condition]
end

function get_outcome_set(environment::ElementaryCellularAutomataEnvironment)
    # Placeholder implementation for measure function
    function measure(domain::DensityClassificationDomain, state::Vector{Int})
        # This should be replaced with the actual logic to measure the outcome based on the domain's criteria
        return sum(state) > length(state) / 2 ? [1.0, 0.0] : [0.0, 1.0]
    end

    final_state = environment.current_state
    outcome_set = measure(environment.domain, final_state)
    return outcome_set
end

end  # End of module

