using CoEvo.Genotypes.FunctionGraphs

function create_fibonacci_function_graph_genotype()
    genotype = FunctionGraphGenotype(
        input_node_ids = [-1],
        bias_node_ids = Int[0],
        hidden_node_ids = [1, 2, 3, 4, 5],
        output_node_ids = [6],
        nodes = Dict(
            6 => FunctionGraphNode(6, :OUTPUT, [
                FunctionGraphConnection(5, 1.0, false)
            ]),
            5 => FunctionGraphNode(5, :ADD, [
                FunctionGraphConnection(3, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            4 => FunctionGraphNode(4, :MULTIPLY, [
                FunctionGraphConnection(2, 1.0, true), 
                FunctionGraphConnection(3, 1.0, true)
            ]),
            3 => FunctionGraphNode(3, :MAXIMUM, [
                FunctionGraphConnection(5, 1.0, true), 
                FunctionGraphConnection(1, 1.0, false)
            ]),
            2 => FunctionGraphNode(2, :IDENTITY, [
                FunctionGraphConnection(1, 1.0, true)
            ]),
            1 => FunctionGraphNode(1, :IDENTITY, [
                FunctionGraphConnection(-1, 1.0, false)
            ]),
            0 => FunctionGraphNode(0, :BIAS, []),
            -1 => FunctionGraphNode(-1, :INPUT, [])
        ),
        n_nodes_per_output = 1
    )
    return genotype 
end

function create_fibonacci_function_graph_phenotype()
    genotype = create_fibonacci_function_graph_genotype()
    phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)
    return phenotype
end

function create_simple_function_graph_genotype()
    # this genotype has hidden nodes 
    # id -1: input function with empty input connections
    # id 0: bias function with empty input connections
    # id 1: identity function with input the bias node, weight value 1
    # id 2: identity function with input the bias node, weight value 1
    # id 3: plus function with inputs id 1 and id 2, weight value 1
    # id 4: plus function with inputs id -1 and id 3, weight value 1
    # id 5: output function with input id 4, weight value 1
    genotype = FunctionGraphGenotype(
        input_node_ids = [-1],
        bias_node_ids = Int[0],
        hidden_node_ids = Int[1, 2, 3, 4],
        output_node_ids = Int[5],
        nodes = Dict(
            5 => FunctionGraphNode(5, :OUTPUT, [
                FunctionGraphConnection(4, 1.0, false)
            ]),
            4 => FunctionGraphNode(4, :ADD, [
                FunctionGraphConnection(-1, 1.0, false), 
                FunctionGraphConnection(3, 1.0, false)
            ]),
            3 => FunctionGraphNode(3, :ADD, [
                FunctionGraphConnection(1, 1.0, false), 
                FunctionGraphConnection(2, 1.0, false)
            ]),
            2 => FunctionGraphNode(2, :IDENTITY, [
                FunctionGraphConnection(0, 1.0, false)
            ]),
            1 => FunctionGraphNode(1, :IDENTITY, [
                FunctionGraphConnection(0, 1.0, false)
            ]),
            0 => FunctionGraphNode(0, :BIAS, []),
            -1 => FunctionGraphNode(-1, :INPUT, [])
        ),
        n_nodes_per_output = 1
    )
    return genotype
end

function create_simple_function_graph_phenotype()
    genotype = create_simple_function_graph_genotype()
    phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)
    return phenotype
end

function Base.show(io::IO, genotype::FunctionGraphGenotype)
    println(io, "FunctionGraphGenotype:")
    for (id, node) in sort(collect(genotype.nodes))

        connections = join(["(" * string(conn.input_node_id, ", ", conn.weight, ", ", conn.is_recurrent, ")") for conn in node.input_connections], ", ")
        println(io, "  ", id, "  => (", id, ", :", node.func, ", [", connections, "])")
    end
end

function Base.isless(a::FunctionGraphNode, b::FunctionGraphNode)
    return a.id < b.id
end