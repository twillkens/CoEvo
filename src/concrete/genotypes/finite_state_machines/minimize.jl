export minimize, minimize_verbose

"""
Hopcroft's DFA minimization algorithm implementation for FiniteStateMachineGenotype.
"""

# Define a struct to encapsulate partition sets and their intersections/differences
struct PartitionIntersectionDiff{T}
    main_partition::Set{T}
    intersection_with_X::Set{T}
    difference_with_X::Set{T}
end

"""
Return the set of states that transition to states in `target_states` using symbol `symbol`.
"""
function get_states_transitioning_to_target_on_symbol(
    symbol::Bool, target_states::Set{T}, links::Dict{Tuple{T, Bool}, T}
) where T
    return Set(
        [origin for ((origin, bit), dest) in links if bit == symbol && dest in target_states]
    )
end

"""
Return all partitions that intersect with `X` and the intersections and differences.
"""
function get_partitions_intersecting_with_X(all_partitions::Set{Set{T}}, X::Set{T}) where T
    intersecting_partitions = PartitionIntersectionDiff[]
    for partition in all_partitions
        intersection = intersect(X, partition)
        if !isempty(intersection) 
            difference = setdiff(partition, X)
            if !isempty(difference)
                push!(intersecting_partitions, PartitionIntersectionDiff(
                    partition, intersection, difference
                ))
            end
        end
    end
    return intersecting_partitions
end


#function get_partitions_intersecting_with_X(all_partitions::Set{Set{T}}, X::Set{T}) where T
#    return [PartitionIntersectionDiff(partition, intersect(X, partition), setdiff(partition, X)) 
#            for partition in all_partitions 
#            if !isempty(intersect(X, partition)) && !isempty(setdiff(partition, X))]
#end

"""
Modify partitions and the working set according to the Hopcroft's algorithm.
"""
function handle_partition_intersection_diff!(
    partition_diff::PartitionIntersectionDiff, 
    all_partitions::Set{Set{T}}, 
    working_set::Set{Set{T}}
) where T
    delete!(all_partitions, partition_diff.main_partition)
    push!(all_partitions, partition_diff.intersection_with_X, partition_diff.difference_with_X)

    if partition_diff.main_partition in working_set
        delete!(working_set, partition_diff.main_partition)
        push!(working_set, partition_diff.intersection_with_X, partition_diff.difference_with_X)
    else
        smaller_partition = length(
            partition_diff.intersection_with_X
            ) <= length(
                partition_diff.difference_with_X
            ) ? 
            partition_diff.intersection_with_X : partition_diff.difference_with_X
        push!(working_set, smaller_partition)
    end
end

"""
Return all states reachable from 'new_states' via links.
"""
function get_reachable_states_from_new(new_states::Set{T}, links::Dict{Tuple{T, Bool}, T}) where T
    return Set(
        [links[(state, symbol)] 
        for state in new_states 
        for symbol in [true, false] 
        if haskey(links, (state, symbol))]
    )
end

"""
Remove non-reachable states from the FSM and return pruned FSM elements.
"""
function remove_unreachable_states(fsm::FiniteStateMachineGenotype)
    reachable_states = Set([fsm.start])
    new_states = Set([fsm.start])
    ones, zeros, links = copy(fsm.ones), copy(fsm.zeros), copy(fsm.links)

    while true
        temp_states = get_reachable_states_from_new(new_states, links)
        new_states = setdiff(temp_states, reachable_states)
        union!(reachable_states, new_states)
        isempty(new_states) && break
    end

    # Filter based on reachability
    filter!(state -> state in reachable_states, ones)
    filter!(state -> state in reachable_states, zeros)
    filter!(link -> link[1][1] in reachable_states && link[2] in reachable_states, links)

    return ones, zeros, links
end

# Main Hopcroft algorithm
function hopcroft_algorithm(fsm::FiniteStateMachineGenotype)
    ones, zeros, links = remove_unreachable_states(fsm)
    all_partitions, working_set = Set([ones, zeros]), Set([ones, zeros])

    while !isempty(working_set)
        current_partition = pop!(working_set)
        for symbol in [true, false]
            transition_states = get_states_transitioning_to_target_on_symbol(
                symbol, current_partition, links
            )
            foreach(
                partition_diff -> handle_partition_intersection_diff!(
                    partition_diff, all_partitions, working_set
                ), 
                get_partitions_intersecting_with_X(all_partitions, transition_states)
            )
        end
    end

    return all_partitions
end

# FSM Merging functions

"""
Merge partition into a single state name.
"""
function merge_partition_into_state_name(partition::Set{String})
    merged_name = join(sort(collect(partition)), "/")
    return contains(merged_name, "/") ? merged_name : string(merged_name, "/")
end

"""
Create a mapping of original states to merged states.
"""
function create_merged_state_map(
    fsm::FiniteStateMachineGenotype, all_partitions::Set{Set{String}}
)
    merged_state_names = map(merge_partition_into_state_name, collect(all_partitions))
    return Dict(original_state => merged_name 
                for original_state in union(fsm.ones, fsm.zeros) 
                for merged_name in merged_state_names 
                if original_state in split(merged_name, "/"))
end

"""
Merge the partitions into a new FSM.
"""
function merge_partitions_for_string_fsm(
    fsm::FiniteStateMachineGenotype{String}, all_partitions::Set{Set{String}}
)
    merged_state_map = create_merged_state_map(fsm, all_partitions)
    new_start = merged_state_map[fsm.start]
    
    new_ones = Set{String}()
    new_zeros = Set{String}()
    new_links = Dict{Tuple{String, Bool}, String}()

    for partition in all_partitions
        old_state = first(partition)
        new_state = merge_partition_into_state_name(partition)

        true_destination = merged_state_map[fsm.links[(old_state, true)]]
        false_destination = merged_state_map[fsm.links[(old_state, false)]]

        new_links[(new_state, true)] = true_destination
        new_links[(new_state, false)] = false_destination

        (old_state in fsm.ones) ? push!(new_ones, new_state) : push!(new_zeros, new_state)
    end

    genotype = FiniteStateMachineGenotype(new_start, new_ones, new_zeros, new_links)

    return genotype, merged_state_map
end

"""
Merge the partitions for FSM with real states.
"""
function merge_partitions_for_real_fsm(
    fsm::FiniteStateMachineGenotype{R}, all_partitions::Set{<:Set{R}}
) where R <: Real
    merged_state_map = Dict(
        x => R(i) for (i, partition) in enumerate(all_partitions) for x in partition
    )
    new_start = merged_state_map[fsm.start]
    new_ones = Set(merged_state_map[state] for state in fsm.ones)
    new_zeros = Set(merged_state_map[state] for state in fsm.zeros)
    new_links = Dict(
        (merged_state_map[origin], symbol) => merged_state_map[destination]
        for ((origin, symbol), destination) in fsm.links 
        if origin in keys(merged_state_map) && destination in keys(merged_state_map)
    )

    genotype = FiniteStateMachineGenotype(new_start, new_ones, new_zeros, new_links)

    return genotype, merged_state_map
end

"""
Minimize FSM using Hopcroft's algorithm and then merge the partitions.
"""
function minimize(fsm::FiniteStateMachineGenotype)
    minimized_partitions = hopcroft_algorithm(fsm)
    minimized_fsm, _ = merge_partitions_for_real_fsm(fsm, minimized_partitions)
    return minimized_fsm
end

function minimize_verbose(fsm::FiniteStateMachineGenotype{Int})
    minimized_partitions = hopcroft_algorithm(fsm)
    minimized_fsm, merged_state_map = merge_partitions_for_real_fsm(fsm, minimized_partitions)
    return minimized_fsm, merged_state_map
end

function minimize_verbose(fsm::FiniteStateMachineGenotype{String})
    minimized_partitions = hopcroft_algorithm(fsm)
    minimized_fsm, merged_state_map = merge_partitions_for_string_fsm(fsm, minimized_partitions)
    return minimized_fsm, merged_state_map
end