export PhylogeneticGraph, add_node!, get_oldest_ancestor, delete_node!

struct PhylogeneticGraph{T}
    parent_mapping::Dict{T, T}    # Child ID to Parent ID
    child_mapping::Dict{T, Set{T}} # Parent ID to Child IDs
    PhylogeneticGraph{T}() where T = new{T}(Dict{T, T}(), Dict{T, Set{T}}())
end

# Overloaded add_node! function for adding a root node
function add_node!(graph::PhylogeneticGraph{T}, node_id::T) where T
    # Check if the node already exists; if not, add it without a parent.
    if !haskey(graph.parent_mapping, node_id) && !haskey(graph.child_mapping, node_id)
        # Initialize the child set for the node to signify it's part of the graph
        graph.child_mapping[node_id] = Set{T}()
    end
end


# Add a new node to the graph
function add_node!(graph::PhylogeneticGraph{T}, parent_id::T, child_id::T) where T
    graph.parent_mapping[child_id] = parent_id
    if !haskey(graph.child_mapping, parent_id)
        graph.child_mapping[parent_id] = Set{T}()
    end
    push!(graph.child_mapping[parent_id], child_id)
end

# Get the oldest ancestor of a node
function get_oldest_ancestor(graph::PhylogeneticGraph{T}, id::T)::T where T
    current_id = id
    while haskey(graph.parent_mapping, current_id)
        current_id = graph.parent_mapping[current_id]
    end
    return current_id
end

# Delete a node from the graph
function delete_node!(graph::PhylogeneticGraph{T}, id::T) where T
    # Remove the node from its parent's child set
    if haskey(graph.parent_mapping, id)
        parent_id = graph.parent_mapping[id]
        if haskey(graph.child_mapping, parent_id)
            delete!(graph.child_mapping[parent_id], id)
        end
        delete!(graph.parent_mapping, id)
    end

    # If the node has children, they become root nodes (disconnected)
    if haskey(graph.child_mapping, id)
        for child_id in collect(graph.child_mapping[id])
            delete!(graph.parent_mapping, child_id) # Remove parent reference
        end
        delete!(graph.child_mapping, id) # Remove the node as a parent
    end
end
