
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

function get_majority_value(values::Vector{Int})
    sum(values) > length(values) / 2 ? 1 : 0
end

function evolve_until_relaxed(rule::Vector{Int}, initial_state::Vector{Int}, max_generations::Int)
    #try
        width = length(initial_state)
        states = zeros(Int, max_generations, width)
        states[1, :] = initial_state
        rule_length = length(rule)
        #println("rule_length = ", rule_length)
        r = Int((log2(rule_length) - 1) / 2)
        #println("r = ", r)

        for gen in 2:max_generations
            is_uniform = true
            previous_state_uniform = states[gen - 1, 1]

            for i in 1:width
                index = 0
                for j = -r:r
                    neighbor_index = mod(i + j - 1, width) + 1
                    index = (index << 1) + states[gen - 1, neighbor_index]
                end
                #states[gen, i] = rule[rule_length - index]
                states[gen, i] = rule[index + 1]
                if states[gen, i] != previous_state_uniform
                    is_uniform = false
                end
            end

            if is_uniform
                return states[1:gen, :], true
            end
        end
        return states, false
    #catch e
    #    println("initial_state = ", initial_state)
    #    println("rule = ", rule)
    #    throw(e)
    #end
end

function covered_improved(R::Vector{Int}, IC::Vector{Int}, M::Int)
    states, is_uniform = evolve_until_relaxed(IC, R, M)
    if is_uniform
        final_state = states[end, :]
        maj_value = get_majority_value(IC)
        return all(x -> x == maj_value, final_state) ? true : false
    else
        return false
    end
end

function generate_variations(bitstring::Vector{<:Real})
    # Original
    O = bitstring
    
    # Reversed
    R = reverse(bitstring)
    
    # Inverted Original
    IO = [1 - bit for bit in O]
    
    # Inverted Reversed
    IR = [1 - bit for bit in R]
    
    # Function to swap halves (applied to both original and reversed, and their inversions)
    function swap_halves(bs)
        midpoint = div(length(bs), 2)
        if length(bs) % 2 == 0
            return vcat(bs[midpoint+1:end], bs[1:midpoint])
        else
            # For odd-length bitstrings, keep the middle element in place
            return vcat(bs[midpoint+2:end], bs[midpoint+1], bs[1:midpoint])
        end
    end
    
    # Swap Halves for Original and Reversed
    SH_O = swap_halves(O)
    SH_R = swap_halves(R)
    
    # Swap Halves for Inverted Original and Inverted Reversed
    SH_IO = swap_halves(IO)
    SH_IR = swap_halves(IR)
    
    return [O, R, IO, IR, SH_O, SH_IO, SH_R, SH_IR]
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