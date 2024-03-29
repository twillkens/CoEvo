
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
            #states[gen, i] = rule[rule_length - index]
            states[gen, i] = rule[index + 1]
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