module Traverse

export get_child_index, all_nodes, get_nodes, get_node, get_root, get_parent_node
export get_child_nodes, get_ancestors, get_descendents, pruned_size

using ...GeneticPrograms: GeneticProgramGenotype, ExpressionNodeGene

"""
    get_child_index(parent_node::ExpressionNodeGene, child_node::ExpressionNodeGene)

Return the index of `child_node` within the children of `parent_node`. 
"""
function get_child_index(parent_node::ExpressionNodeGene, child_node::ExpressionNodeGene)
    findfirst(x -> x == child_node.id, parent_node.child_ids)
end

"""
    all_nodes(geno::GeneticProgramGenotype)

Return a dictionary combining both function nodes and terminal nodes of the given genotype.
"""
function all_nodes(geno::GeneticProgramGenotype)
    merge(geno.functions, geno.terminals)
end

"""
    get_nodes(geno::GeneticProgramGenotype, ids::Vector{Int})

Retrieve specific nodes from `geno` based on the provided vector of `ids`.
"""
function get_nodes(geno::GeneticProgramGenotype, ids::Vector{Int})
    all_nodes = merge(geno.functions, geno.terminals)
    [haskey(all_nodes, id) ? all_nodes[id] : nothing for id in ids]
end

"""
    get_node(geno::GeneticProgramGenotype, id::Union{Int, Nothing})

Retrieve a specific node from `geno` based on the provided `id`.
"""
function get_node(geno::GeneticProgramGenotype, id::Union{Int, Nothing})
    if id === nothing
        return nothing
    end
    all_nodes = merge(geno.functions, geno.terminals)
    haskey(all_nodes, id) ? all_nodes[id] : nothing
end

"""
    get_root(geno::GeneticProgramGenotype)

Retrieve the root node from `geno`.
"""
function get_root(geno::GeneticProgramGenotype)
    get_node(geno, geno.root_id)
end

"""
    get_parent_node(geno::GeneticProgramGenotype, node::ExpressionNodeGene)

Retrieve the parent node of a given `node` in the genotype `geno`.
"""
function get_parent_node(geno::GeneticProgramGenotype, node::ExpressionNodeGene)
    if node.parent_id === nothing
        return nothing
    end
    return get_node(geno, node.parent_id)
end

"""
    get_child_nodes(geno::GeneticProgramGenotype, node::ExpressionNodeGene)

Retrieve children nodes of a given `node` in the genotype `geno`.
"""
function get_child_nodes(geno::GeneticProgramGenotype, node::ExpressionNodeGene)
    if length(node.child_ids) == 0
        return ExpressionNodeGene[]
    end
    get_nodes(geno, node.child_ids)
end

"""
    get_ancestors(geno::GeneticProgramGenotype, root::ExpressionNodeGene)

Recursively gather all parent nodes of a `root` node in the genotype `geno`.
"""
function get_ancestors(geno::GeneticProgramGenotype, root::ExpressionNodeGene)
    if root.parent_id === nothing
        return ExpressionNodeGene[]
    end
    parent_node = get_parent_node(geno, root)
    [parent_node, get_ancestors(geno, parent_node)...]
end

function get_ancestors(geno::GeneticProgramGenotype, root_id::Int)
    get_ancestors(geno, get_node(geno, root_id))
end

"""
    get_descendents(geno::GeneticProgramGenotype, root::ExpressionNodeGene)

Recursively gather all child, grandchild, etc., nodes of a `root` node in the genotype `geno`.
"""
function get_descendents(geno::GeneticProgramGenotype, root::ExpressionNodeGene)
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

function get_descendents(geno::GeneticProgramGenotype, root_id::Int)
    get_descendents(geno, get_node(geno, root_id))
end


"""
    pruned_size(geno::GeneticProgramGenotype)

Compute the pruned size of the genotype `geno` by counting the descendants of the root node.
"""
function pruned_size(geno::GeneticProgramGenotype)::Int
    descendants = get_descendents(geno, geno.root_id)
    return length(descendants) + 1
end

end