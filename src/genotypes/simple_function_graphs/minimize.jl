export get_size, minimize, remove_node_and_redirect, get_prunable_genes
export substitute_node_with_bias_connection

import ..Genotypes: get_prunable_genes

"""
    get_size(genotype::SimpleFunctionGraphGenotype) -> Int

Get the size of a `SimpleFunctionGraphGenotype` as determined by the number of hidden nodes it contains.

# Arguments:
- `genotype::SimpleFunctionGraphGenotype`: The genotype whose size we wish to determine.

# Returns:
- An integer representing the number of hidden nodes in the genotype.
"""
function get_size(genotype::SimpleFunctionGraphGenotype)
    return length(genotype.hidden_ids)
end

function get_active_gene_ids(genotype::SimpleFunctionGraphGenotype)
    # A Set to store IDs of essential nodes.
    active_gene_ids = Set{Int}()

    # A function to recursively find essential nodes by traversing input connections.
    function find_active_gene_ids(node_id::Int)
        # Avoid repeated work if the node is already identified as essential.
        if node_id in active_gene_ids
            return
        end

        # Add the current node to essential nodes.
        push!(active_gene_ids, node_id)

        # Find the node by its ID.
        node = genotype[node_id]
        #println("node = ", node)

        # Recursively call for all input connections of the current node, if it exists.
        for edge in node.edges
            find_active_gene_ids(edge.target)
        end
    end

    # Initialize the search from each output node.
    for output_id in genotype.output_ids
        find_active_gene_ids(output_id)
    end

    # Ensuring input, bias, and output nodes are always essential.
    active_gene_ids = union(
        active_gene_ids, genotype.input_ids, 
        genotype.bias_ids, genotype.output_ids
    )
    return active_gene_ids
end

function minimize(genotype::SimpleFunctionGraphGenotype)

    active_gene_ids = get_active_gene_ids(genotype)
    # Construct the minimized genotype, keeping only essential nodes.
    minimized_nodes = filter(node -> node.id in active_gene_ids, genotype.nodes)

    # Return a new SimpleFunctionGraphGenotype with minimized nodes.
    minimized_genotype = SimpleFunctionGraphGenotype(minimized_nodes)
    return minimized_genotype
end

function get_active_nodes(genotype::SimpleFunctionGraphGenotype)
    active_gene_ids = get_active_gene_ids(genotype)
    active_nodes = filter(node -> node.id in active_gene_ids, genotype.nodes)
    return active_nodes
end

function get_inactive_nodes(genotype::SimpleFunctionGraphGenotype)
    active_gene_ids = get_active_gene_ids(genotype)
    inactive_nodes = filter(node -> !(node.id in active_gene_ids), genotype.nodes)
    return inactive_nodes
end
