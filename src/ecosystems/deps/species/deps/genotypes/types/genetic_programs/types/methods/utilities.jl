
function all_nodes(geno::BasicGeneticProgramGenotype)
    merge(geno.funcs, geno.terms)
end

# Get selected nodes from the genotype as a vector
function get_nodes(geno::BasicGeneticProgramGenotype, gids::Vector{Int})
    all_nodes = merge(geno.funcs, geno.terms)
    [haskey(all_nodes, gid) ? all_nodes[gid] : nothing for gid in gids]
end

# Get specific node from the genotype
function get_node(geno::BasicGeneticProgramGenotype, gid::Union{Int, Nothing})
    if gid === nothing
        return nothing
    end
    all_nodes = merge(geno.funcs, geno.terms)
    haskey(all_nodes, gid) ? all_nodes[gid] : nothing
end

function get_root(geno::BasicGeneticProgramGenotype)
    get_node(geno, geno.root_gid)
end

# Get parent node of a node in the genotype
function get_parent_node(geno::BasicGeneticProgramGenotype, node::ExpressionNodeGene)
    if node.parent_gid === nothing
        return nothing
    end
    return get_node(geno, node.parent_gid)
end

# Get children nodes of a node in the genotype
function get_child_nodes(geno::BasicGeneticProgramGenotype, node::ExpressionNodeGene)
    if length(node.child_gids) == 0
        return ExpressionNodeGene[]
    end
    get_nodes(geno, node.child_gids)
end

# Recursively gather all parent nodes of a node in the genotype
function get_ancestors(geno::BasicGeneticProgramGenotype, root::ExpressionNodeGene)
    if root.parent_gid === nothing
        return ExpressionNodeGene[]
    end
    parent_node = get_parent_node(geno, root)
    [parent_node, get_ancestors(geno, parent_node)...]
end

# Recursivly gather al child, grandchild, etc, nodes of a node in the genotype
function get_descendents(geno::BasicGeneticProgramGenotype, root::ExpressionNodeGene)
    if length(root.child_gids) == 0
        return ExpressionNodeGene[]
    end
    nodes = ExpressionNodeGene[]
    for child_node in get_child_nodes(geno, root)
        push!(nodes, child_node)
        append!(nodes, get_descendents(geno, child_node))
    end
    nodes
end

function get_descendents(geno::BasicGeneticProgramGenotype, root_gid::Int)
    get_descendents(geno, get_node(geno, root_gid))
end

function get_ancestors(geno::BasicGeneticProgramGenotype, root_gid::Int)
    get_ancestors(geno, get_node(geno, root_gid))
end

function pruned_size(geno::BasicGeneticProgramGenotype)::Int
    # Get all descendants of the root node
    descendants = get_descendents(geno, geno.root_gid)
    
    # Include the root node in the count
    return length(descendants) + 1
end