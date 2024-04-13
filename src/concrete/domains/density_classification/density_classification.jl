
module DensityClassification

export DensityClassificationDomain, Covers, covered_improved, evolve_until_relaxed, get_majority_value

import ....Interfaces: measure, get_outcome_set

using Base: @kwdef
using ....Abstract: Metric, Domain

# Assuming ElementaryCellularAutomataDomain and related phenotype definitions are properly defined elsewhere
struct Covers <: Metric end

Base.@kwdef struct DensityClassificationDomain{M <: Metric} <: Domain{M}
    outcome_metric::M = Covers()
    max_timesteps::Int = 320
end

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

function get_majority_value(values::Vector{Int})
    sum(values) > length(values) / 2 ? 1 : 0
end

function evolve_until_relaxed(rule::Vector{Int}, initial_state::Vector{Int}, max_generations::Int)
    width = length(initial_state)
    states = zeros(Int, max_generations, width)
    states[1, :] = initial_state
    rule_length = length(rule)
    #println("rule_length = ", rule_length)
    r = Int((log2(rule_length) - 1) / 2)
    #println("r = ", r)

    for gen in 2:max_generations
        for i in 1:width
            index = 0
            for j = -r:r
                neighbor_index = mod(i + j - 1, width) + 1
                index = (index << 1) + states[gen - 1, neighbor_index]
            end
            #states[gen, i] = rule[rule_length - index]
            states[gen, i] = rule[index + 1]
        end
        is_uniform = sum(states[gen, :]) == 0 || sum(states[gen, :]) == width

        if is_uniform
            return states[1:gen, :], true
        end
    end
    return states, false
end

function covered_improved(R::Vector{Int}, IC::Vector{Int}, M::Int)
    states, is_uniform = evolve_until_relaxed(R, IC, M)
    if is_uniform
        final_state = states[end, :]
        maj_value = get_majority_value(IC)
        return all(x -> x == maj_value, final_state) ? true : false
    else
        return false
    end
end


function get_outcome_set(
    domain::DensityClassificationDomain{Covers},
    rule::Vector{<:Real},
    initial_condition::Vector{<:Real}
)
    #variations = generate_variations(initial_condition)
    #scores = [covered_improved(rule, ic, domain.max_timesteps) for ic in variations]
    #inverted_scores = [1 - score for score in scores]
    learner_passed = covered_improved(rule, initial_condition, domain.max_timesteps)
    return Float64[learner_passed, 1 - learner_passed]
end


end