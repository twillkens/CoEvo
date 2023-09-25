
function get_child_index(parent_node::ExpressionNodeGene, child_node::ExpressionNodeGene)
    findfirst(x -> x == child_node.id, parent_node.child_ids)
end

function all_nodes(geno::BasicGeneticProgramGenotype)
    merge(geno.functions, geno.terminals)
end

# Get selected nodes from the genotype as a vector
function get_nodes(geno::BasicGeneticProgramGenotype, ids::Vector{Int})
    all_nodes = merge(geno.functions, geno.terminals)
    [haskey(all_nodes, id) ? all_nodes[id] : nothing for id in ids]
end

# Get specific node from the genotype
function get_node(geno::BasicGeneticProgramGenotype, id::Union{Int, Nothing})
    if id === nothing
        return nothing
    end
    all_nodes = merge(geno.functions, geno.terminals)
    haskey(all_nodes, id) ? all_nodes[id] : nothing
end

function get_root(geno::BasicGeneticProgramGenotype)
    get_node(geno, geno.root_id)
end

# Get parent node of a node in the genotype
function get_parent_node(geno::BasicGeneticProgramGenotype, node::ExpressionNodeGene)
    if node.parent_id === nothing
        return nothing
    end
    return get_node(geno, node.parent_id)
end

# Get children nodes of a node in the genotype
function get_child_nodes(geno::BasicGeneticProgramGenotype, node::ExpressionNodeGene)
    if length(node.child_ids) == 0
        return ExpressionNodeGene[]
    end
    get_nodes(geno, node.child_ids)
end

# Recursively gather all parent nodes of a node in the genotype
function get_ancestors(geno::BasicGeneticProgramGenotype, root::ExpressionNodeGene)
    if root.parent_id === nothing
        return ExpressionNodeGene[]
    end
    parent_node = get_parent_node(geno, root)
    [parent_node, get_ancestors(geno, parent_node)...]
end

# Recursivly gather al child, grandchild, etc, nodes of a node in the genotype
function get_descendents(geno::BasicGeneticProgramGenotype, root::ExpressionNodeGene)
    if length(root.child_ids) == 0
        return ExpressionNodeGene[]
    end
    nodes = ExpressionNodeGene[]
    for child_node in get_child_nodes(geno, root)
        push!(nodes, child_node)
        append!(nodes, get_descendents(geno, child_node))
    end
    nodes
end

function get_descendents(geno::BasicGeneticProgramGenotype, root_id::Int)
    get_descendents(geno, get_node(geno, root_id))
end

function get_ancestors(geno::BasicGeneticProgramGenotype, root_id::Int)
    get_ancestors(geno, get_node(geno, root_id))
end

function replace_child!(
    parent_node::ExpressionNodeGene, 
    old_child_node::ExpressionNodeGene, 
    new_child_node::ExpressionNodeGene
)
    child_idx = get_child_index(parent_node, old_child_node)
    parent_node.child_ids[child_idx] = new_child_node.id
end

function replace_child!(parent_id::Int, old_child_id::Int, new_child_id::Int)
    parent_node = get_node(geno, parent_id)
    old_child_node = get_node(geno, old_child_id)
    new_child_node = get_node(geno, new_child_id)
    replace_child(parent_node, old_child_node, new_child_node)
end


function pruned_size(geno::BasicGeneticProgramGenotype)::Int
    # Get all descendants of the root node
    descendants = get_descendents(geno, geno.root_id)
    
    # Include the root node in the count
    return length(descendants) + 1
end