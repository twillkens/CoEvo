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
    
    # Saving node-related data.
    geno_group["node_ids"] = keys(geno.nodes)
    geno_group["node_functions"] = [node.func for node in values(geno.nodes)]
    
    # Collecting connection-related data.
    connection_input_ids = Int[]
    connection_weights = Float64[]
    connection_recurrency = Bool[]
    for node in values(geno.nodes)
        append!(connection_input_ids, [conn.input_node_id for conn in node.input_connections])
        append!(connection_weights, [conn.weight for conn in node.input_connections])
        append!(connection_recurrency, [conn.is_recurrent for conn in node.input_connections])
    end
    
    # Saving connection-related data.
    geno_group["connection_input_ids"] = connection_input_ids
    geno_group["connection_weights"] = connection_weights
    geno_group["connection_recurrency"] = connection_recurrency
end


end