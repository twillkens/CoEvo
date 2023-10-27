
function pretty_print(genotype::FunctionGraphGenotype)
    println("FunctionGraphGenotype:")
    println("  Input Nodes: ", join(genotype.input_node_ids, ", "))
    println("  Bias Nodes: ", join(genotype.bias_node_ids, ", "))
    println("  Hidden Nodes: ", join(genotype.hidden_node_ids, ", "))
    println("  Output Nodes: ", join(genotype.output_node_ids, ", "))

    println("\nNodes:")
    for (id, node) in genotype.nodes
        println("  Node ID: ", id)
        println("    Function: ", node.func)
        println("    Connections:")
        for conn in node.input_connections
            println("      Connected to Node ID: ", conn.input_node_id)
            println("        Weight: ", conn.weight)
            println("        Recurrent: ", conn.is_recurrent ? "Yes" : "No")
        end
        println()  # Empty line for better readability between nodes
    end
end

