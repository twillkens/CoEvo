module FunctionGraphs

export FunctionGraphGenotypeLoader

using JLD2: Group
using ....Ecosystems.Species.Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphNode
using ....Ecosystems.Species.Genotypes.FunctionGraphs: FunctionGraphConnection, GraphFunction
using ....Ecosystems.Species.Genotypes.FunctionGraphs: FUNCTION_MAP
using ...Loaders.Abstract: Loader

import ...Loaders.Interfaces: load_genotype

struct FunctionGraphGenotypeLoader <: Loader end

function load_genotype(::FunctionGraphGenotypeLoader, geno_group::Group)
    # Load node id lists directly.
    input_node_ids = geno_group["input_node_ids"]
    bias_node_ids = geno_group["bias_node_ids"]
    hidden_node_ids = geno_group["hidden_node_ids"]
    output_node_ids = geno_group["output_node_ids"]
    n_nodes_per_output = geno_group["n_nodes_per_output"]
    
    # Load node-related data.
    node_ids = geno_group["node_ids"]
    node_functions = geno_group["node_functions"]
    
    # Initialize an empty nodes dictionary.
    nodes = Dict{Int, FunctionGraphNode}()
    for (id, func) in zip(node_ids, node_functions)
        nodes[id] = FunctionGraphNode(id, func, FunctionGraphConnection[])
    end
    
    # Load connection data and establish connections.
    connection_data = geno_group["connection_data"]
    for (node_id, input_id, weight, is_recurrent) in connection_data
        conn = FunctionGraphConnection(input_id, weight, is_recurrent)
        push!(nodes[node_id].input_connections, conn)
    end
    
    # Construct and return the FunctionGraphGenotype.
    genotype = FunctionGraphGenotype(
        input_node_ids=input_node_ids,
        bias_node_ids=bias_node_ids,
        hidden_node_ids=hidden_node_ids,
        output_node_ids=output_node_ids,
        nodes=nodes,
        n_nodes_per_output=n_nodes_per_output
    )
    return genotype
end


end