using Random
using Plots

function generate_IC(n::Int, rho::Int)
    v = Int[zeros(rho) ; ones(n - rho)]
    IC = shuffle(v)
    return IC
end

function generate_IC(n::Int)
    rho = rand(1:n)
    IC = generate_IC(n, rho)
    return IC
end

using Random

function generate_unbiased_ICs(n::Int, n_samples::Int)
    # Initialize an array to hold the generated ICs
    ICs = Vector{Vector{Int}}(undef, n_samples)
    
    # Generate each IC
    for i in 1:n_samples
        # For an unbiased distribution, each bit has a 50% chance of being 1 or 0
        IC = rand(0:1, n)
        ICs[i] = IC
    end
    
    return ICs
end

using Random



function plot_eca(states::Matrix{Int})
    # Reverse the states matrix to have the initial state at the top
    states_reversed = reverse(states, dims=1)
    
    # Define a custom color gradient: 0 -> white, 1 -> black
    cmap = cgrad([:white, :black])
    
    # Plot using a direct image representation with the custom color gradient
    heatmap(
        states_reversed, aspect_ratio=1, colorbar=false, legend=false, ticks=nothing, 
        border=:none, cmap=cmap
    )
end

function evolve(initial_state::Vector{Int}, rule::Vector{Int}, generations::Int)
    width = length(initial_state)
    states = zeros(Int, generations, width)
    states[1, :] = initial_state
    rule_length = length(rule)
    
    # Infer the neighborhood size r from the rule vector length
    r = Int((log2(rule_length) - 1) / 2)

    for gen in 2:generations
        for i in 1:width
            index = 0
            
            # Use modular arithmetic to handle wrapping
            for j = -r:r
                neighbor_index = mod(i + j - 1, width) + 1
                index = (index << 1) + states[gen - 1, neighbor_index]
            end
            
            # Apply the rule to determine the new state
            states[gen, i] = rule[rule_length - index]
        end
    end

    return states
end

using Plots

function majority(values::Vector{Int})
    sum(values) > length(values) / 2 ? 1 : 0
end

function covered(R::Vector{Int}, IC::Vector{Int}, M::Int)
    # Evolve the IC for M steps using the previously defined evolve function
    # Ensure the evolve function is defined in your environment and returns a Matrix{Int}
    states = evolve(IC, R, M)
    
    # Determine the majority value in the IC
    maj_value = majority(IC)
    
    # Check the final state (last row of the states matrix)
    final_state = states[end, :]
    
    # Check if the final state has "relaxed" to a uniform state matching the majority value
    if all(x -> x == maj_value, final_state)
        return 1  # The system has relaxed to the expected majority state
    else
        return 0  # The system has not relaxed to the expected majority state
    end
end
using StatsBase



using Random
using StatsBase

function evolve_until_relaxed(initial_state::Vector{Int}, rule::Vector{Int}, max_generations::Int)
    width = length(initial_state)
    states = zeros(Int, max_generations, width)
    states[1, :] = initial_state
    rule_length = length(rule)
    r = Int((log2(rule_length) - 1) / 2)

    for gen in 2:max_generations
        is_uniform = true
        previous_state_uniform = states[gen - 1, 1]

        for i in 1:width
            index = 0
            for j = -r:r
                neighbor_index = mod(i + j - 1, width) + 1
                index = (index << 1) + states[gen - 1, neighbor_index]
            end
            states[gen, i] = rule[rule_length - index]
            if states[gen, i] != previous_state_uniform
                is_uniform = false
            end
        end

        if is_uniform
            return states[1:gen, :], true
        end
    end
    return states, false
end

function covered_improved(R::Vector{Int}, IC::Vector{Int}, M::Int)
    states, is_uniform = evolve_until_relaxed(IC, R, M)
    if is_uniform
        final_state = states[end, :]
        maj_value = majority(IC)
        return all(x -> x == maj_value, final_state) ? true : false
    else
        return false
    end
end

c1 = "00000000010111110000000001011111"
c2 = "00000000010111111111111101011111"
c1 = [parse(Int, c) for c in c1]
c2 = [parse(Int, c) for c in c2]
GKL = collect(reverse([c1 ; c1 ; c2 ; c2]))
COEVO = [1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0]
ics = generate_unbiased_ICs(149, 10000)

function run_test()
ics = generate_unbiased_ICs(149, 10000)
t = time()
scores = [covered(GKL, ic, 320) for ic in ics]
println("mean GKL score: ", mean(scores), " time: ", time() - t)
t = time()
scores = [covered(COEVO, ic, 320) for ic in ics]
println("mean COEVO score: ", mean(scores), " time: ", time() - t)


# Example usage
t = time()
scores_gkl = [covered_improved(GKL, ic, 320) for ic in ics]
mean_score_gkl = mean(scores_gkl)
println("Improved mean GKL score: ", mean_score_gkl, " time: ", time() - t)
t = time()
scores_coevo = [covered_improved(COEVO, ic, 320) for ic in ics]
mean_score_coevo = mean(scores_coevo)

println("Improved mean COEVO score: ", mean_score_coevo, " time: ", time() - t)
end


using CoEvo.Concrete.Environments.Stateless
using CoEvo.Concrete.Phenotypes.Vectors


using CoEvo.Abstract
using CoEvo.Interfaces
import ...Interfaces: get_outcome_set

# Assuming ElementaryCellularAutomataDomain and related phenotype definitions are properly defined elsewhere
struct Covers <: Metric end

Base.@kwdef struct ElementaryCellularAutomataDomain{M <: Metric} <: Domain{M}
    outcome_metric::M = Covers()
    max_timesteps::Int = 320
end

function get_outcome_set(
    environment::StatelessEnvironment{D, P1, P2}
) where {D <: ElementaryCellularAutomataDomain, P1 <: Phenotype, P2 <: Phenotype}
    # Assuming the phenotype's `act!` method returns a tuple of (initial configuration, rule)
    rule = act!(environment.entity_1)
    ic = act!(environment.entity_2)
    is_covered = covered_improved(rule, ic, environment.domain.max_timesteps)
    if is_covered
        return [1.0, 0.0]
    else
        return [0.0, 1.0]
    end
    return outcome_set
end

environment_creator = StatelessEnvironmentCreator(ElementaryCellularAutomataDomain())
environment = create_environment(environment_creator, GKL, ics[1])
outcome = get_outcome_set(environment)
environments = [create_environment(environment_creator, GKL, ic) for ic in ics]
t = time()
outcomes = [first(get_outcome_set(env)) for env in environments]
println("mean GKL score: ", mean(outcomes))
println("time: ", time() - t)