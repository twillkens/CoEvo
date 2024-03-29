
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