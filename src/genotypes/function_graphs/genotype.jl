export FunctionGraphGenotype, FunctionGraphGenotypeCreator
export FunctionGraphConnection, FunctionGraphNode, pretty_print

@kwdef mutable struct FunctionGraphConnection
    input_node_id::Int
    weight::Float64
    is_recurrent::Bool
end

function Base.:(==)(a::FunctionGraphConnection, b::FunctionGraphConnection)
    return a.input_node_id == b.input_node_id && 
           isapprox(a.weight, b.weight) && 
           a.is_recurrent == b.is_recurrent
end

function Base.hash(a::FunctionGraphConnection, h::UInt)
    return hash(a.input_node_id, hash(a.weight, hash(a.is_recurrent, h)))
end


@kwdef struct FunctionGraphNode
    id::Int
    func::Symbol
    input_connections::Vector{FunctionGraphConnection}
end

function Base.:(==)(a::FunctionGraphNode, b::FunctionGraphNode)
    return a.id == b.id && 
           a.func == b.func && 
           a.input_connections == b.input_connections  # Note: relies on `==` for FunctionGraphConnection
end

function Base.hash(a::FunctionGraphNode, h::UInt)
    return hash(a.id, hash(a.func, hash(a.input_connections, h)))  # Note: relies on `hash` for FunctionGraphConnection
end

@kwdef struct FunctionGraphGenotype <: Genotype
    input_node_ids::Vector{Int}
    bias_node_ids::Vector{Int}
    hidden_node_ids::Vector{Int}
    output_node_ids::Vector{Int}
    nodes::Dict{Int, FunctionGraphNode}
    n_nodes_per_output::Int
end

function Base.:(==)(a::FunctionGraphGenotype, b::FunctionGraphGenotype)
    # Check each field for equality
    return a.input_node_ids == b.input_node_ids && 
           a.bias_node_ids == b.bias_node_ids &&
           a.hidden_node_ids == b.hidden_node_ids &&
           a.output_node_ids == b.output_node_ids &&
           a.nodes == b.nodes  # Note: relies on `==` for FunctionGraphNode
end


function get_size(genotype::FunctionGraphGenotype)
    return length(genotype.hidden_node_ids)
end

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


@kwdef struct FunctionGraphGenotypeCreator <: GenotypeCreator
    n_inputs::Int
    n_bias::Int
    n_outputs::Int
    n_nodes_per_output::Int
end


function create_ids_and_nodes(
    gene_id_counter::Counter,
    function_symbol::Symbol,
    n_nodes::Int
)
    node_ids = next!(gene_id_counter, n_nodes)
    nodes = Dict(
        id => FunctionGraphNode(
            id = id, 
            func = function_symbol, 
            input_connections = FunctionGraphConnection[]
        ) for id in node_ids
    )
    return node_ids, nodes
end

function create_output_ids_and_nodes(
    genotype_creator::FunctionGraphGenotypeCreator, 
    random_number_generator::AbstractRNG,
    gene_id_counter::Counter,
    input_node_ids::Vector{Int},
)
    n_output_nodes = genotype_creator.n_outputs * genotype_creator.n_nodes_per_output
    output_node_ids = next!(gene_id_counter, n_output_nodes)
    output_nodes = Dict(
        map(output_node_ids) do id
            input_connection_id = rand(random_number_generator, input_node_ids)[1]
            input_connection = FunctionGraphConnection(
                input_node_id = input_connection_id, 
                weight = 0.0, 
                is_recurrent = false
            )
            output_node = FunctionGraphNode(
                id = id, 
                func = :OUTPUT, 
                input_connections = [input_connection]
            )
            return id => output_node
        end
    )
    return output_node_ids, output_nodes
end

function create_genotypes(
    genotype_creator::FunctionGraphGenotypeCreator, 
    random_number_generator::AbstractRNG,
    gene_id_counter::Counter,
    n_population::Int
)
    genotypes = FunctionGraphGenotype[]
    for _ in 1:n_population
        input_node_ids, input_nodes = create_ids_and_nodes(
            gene_id_counter, :INPUT, genotype_creator.n_inputs
        )
        bias_node_ids, bias_nodes = create_ids_and_nodes(
            gene_id_counter, :BIAS, genotype_creator.n_bias
        )
        available_input_ids = [input_node_ids; bias_node_ids]
        output_node_ids, output_nodes = create_output_ids_and_nodes(
            genotype_creator, random_number_generator, gene_id_counter, available_input_ids
        )
        nodes = merge(input_nodes, bias_nodes, output_nodes)
        genotype = FunctionGraphGenotype(
            input_node_ids = input_node_ids, 
            bias_node_ids = bias_node_ids,
            output_node_ids = output_node_ids, 
            hidden_node_ids = Int[], 
            nodes = nodes,
            n_nodes_per_output = genotype_creator.n_nodes_per_output
        )
        push!(genotypes, genotype)
    end

    return genotypes
end

function minimize(genotype::FunctionGraphGenotype)
    # A Set to store IDs of essential nodes.
    essential_nodes_ids = Set{Int}()
    
    # A function to recursively find essential nodes by traversing input connections.
    function find_essential_nodes(node_id::Int)
        # Avoid repeated work if the node is already identified as essential.
        if node_id in essential_nodes_ids
            return
        end
        
        # Add the current node to essential nodes.
        push!(essential_nodes_ids, node_id)
        
        # Recursively call for all input connections of the current node.
        for conn in genotype.nodes[node_id].input_connections
            find_essential_nodes(conn.input_node_id)
        end
    end
    
    # Initialize the search from each output node.
    for output_node_id in genotype.output_node_ids
        find_essential_nodes(output_node_id)
    end
    
    # Ensuring input, bias, and output nodes are always essential.
    union!(essential_nodes_ids, genotype.input_node_ids, genotype.bias_node_ids, genotype.output_node_ids)

    # Construct the minimized genotype, keeping only essential nodes.
    minimized_nodes = Dict(id => node for (id, node) in genotype.nodes if id in essential_nodes_ids)

    # Return a new FunctionGraphGenotype with minimized nodes and unaltered input, bias, and output nodes.
    minimized_genotype = FunctionGraphGenotype(
        input_node_ids = genotype.input_node_ids, 
        bias_node_ids = genotype.bias_node_ids, 
        hidden_node_ids = filter(id -> id in essential_nodes_ids, genotype.hidden_node_ids), 
        output_node_ids = genotype.output_node_ids, 
        nodes = minimized_nodes,
        n_nodes_per_output = genotype.n_nodes_per_output
    )
    return minimized_genotype
end