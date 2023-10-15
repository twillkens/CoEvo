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
    
    # Load node-related data.
    node_ids = geno_group["node_ids"]
    node_functions = geno_group["node_functions"]
    
    # Load connection-related data.
    connection_input_ids = geno_group["connection_input_ids"]
    connection_weights = geno_group["connection_weights"]
    connection_recurrency = geno_group["connection_recurrency"]
    
    # Construct FunctionGraphConnection and FunctionGraphNode objects.
    nodes = Dict{Int, FunctionGraphNode}()
    start_idx = 1
    for (id, func) in zip(node_ids, node_functions)
        # Determine the number of connections based on the function's arity.
        arity = FUNCTION_MAP[func].arity
        
        # Extract the relevant connections.
        conns = [
            FunctionGraphConnection(
                connection_input_ids[idx],
                connection_weights[idx],
                connection_recurrency[idx]
            )
            for idx in start_idx:(start_idx + arity - 1)
        ]
        
        # Construct the node and add it to the dict.
        nodes[id] = FunctionGraphNode(id, func, conns)
        
        # Update the starting index for the next node.
        start_idx += arity
    end
    
    # Construct and return the FunctionGraphGenotype.
    genotype = FunctionGraphGenotype(
        input_node_ids=input_node_ids,
        bias_node_ids=bias_node_ids,
        hidden_node_ids=hidden_node_ids,
        output_node_ids=output_node_ids,
        nodes=nodes
    )
    return genotype
end

end