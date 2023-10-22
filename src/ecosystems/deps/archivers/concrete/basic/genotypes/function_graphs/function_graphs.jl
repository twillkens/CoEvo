module FunctionGraphs

using JLD2: Group

using .....Ecosystems.Species.Genotypes.FunctionGraphs: FunctionGraphGenotype
using .....Ecosystems.Species.Genotypes.FunctionGraphs: FunctionGraphNode, FunctionGraphConnection, GraphFunction
using .....Ecosystems.Species.Genotypes.FunctionGraphs: FUNCTION_MAP
#using .....Ecosystems.Species.Genotypes.GeneticPrograms: GeneticProgramGenotype, ExpressionNodeGene
using ...Basic: BasicArchiver

import ....Archivers.Interfaces: save_genotype!

function save_genotype!(::BasicArchiver, geno_group::Group, geno::FunctionGraphGenotype)
    # Saving node id lists.
    geno_group["input_node_ids"] = geno.input_node_ids
    geno_group["bias_node_ids"] = geno.bias_node_ids
    geno_group["hidden_node_ids"] = geno.hidden_node_ids
    geno_group["output_node_ids"] = geno.output_node_ids
    geno_group["n_nodes_per_output"] = geno.n_nodes_per_output
    
    # Ensure ordered saving of node-related data.
    ordered_node_ids = sort(collect(keys(geno.nodes)))
    ordered_nodes = [geno.nodes[id] for id in ordered_node_ids]
    
    geno_group["node_ids"] = ordered_node_ids
    geno_group["node_functions"] = [node.func for node in ordered_nodes]
    
    # Collecting and saving connection-related data in a structured way.
    connection_data = []
    for node in ordered_nodes
        for conn in node.input_connections
            push!(connection_data, (node.id, conn.input_node_id, conn.weight, conn.is_recurrent))
        end
    end
    
    geno_group["connection_data"] = connection_data
end



end