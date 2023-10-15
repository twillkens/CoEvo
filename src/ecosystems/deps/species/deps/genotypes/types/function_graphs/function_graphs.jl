module FunctionGraphs

export FunctionGraphGenotype, FunctionGraphGenotypeCreator, FUNCTION_MAP
export FunctionGraphConnection, FunctionGraphNode, GraphFunction
export pretty_print

using Random: AbstractRNG
using ...Genotypes.Abstract: Genotype, GenotypeCreator
using CoEvo.Ecosystems.Utilities.Counters: Counter, next!


import ...Genotypes.Interfaces: create_genotypes


@kwdef struct GraphFunction
    name::Symbol
    func::Function
    arity::Int
end

const FUNCTION_MAP = Dict(
    :INPUT => GraphFunction(:INPUT, identity, 0),
    :BIAS => GraphFunction(:BIAS, (args...) -> 1.0, 0),
    :OUTPUT => GraphFunction(:OUTPUT, identity, 1),

    :IDENTITY => GraphFunction(:IDENTITY, identity, 1),

    :ADD => GraphFunction(:ADD, (+), 2),
    :SUBTRACT => GraphFunction(:SUBTRACT, (-), 2),
    :MULTIPLY => GraphFunction(:MULTIPLY, (*), 2),
    :DIVIDE => GraphFunction(:DIVIDE, ((x, y) -> y == 0 ? 1.0 : x / y), 2),

    :MAXIMUM => GraphFunction(:MAXIMUM, max, 2),
    :MINIMUM => GraphFunction(:MINIMUM, min, 2),

    :SIN => GraphFunction(:SIN, (x) -> isinf(x) ? π : sin(x), 1),
    :COSINE => GraphFunction(:COSINE, (x) -> isinf(x) ? π : cos(x), 1),
    :SIGMOID => GraphFunction(:SIGMOID, (x -> 1 / (1 + exp(-x))), 1),
    :TANH => GraphFunction(:TANH, tanh, 1),
    :RELU => GraphFunction(:RELU, (x -> x < 0 ? 0 : x), 1),

    :AND => GraphFunction(:AND, ((x, y) -> Bool(x) && Bool(y)), 2),
    :OR => GraphFunction(:OR, ((x, y) -> Bool(x) || Bool(y)), 2),
    :NAND => GraphFunction(:NAND, ((x, y) -> !(Bool(x) && Bool(y))), 2),
    :XOR => GraphFunction(:XOR, ((x, y) -> Bool(x) ⊻ Bool(y)), 2),
)

function(graph_function::GraphFunction)(args...)
    output = graph_function.func(args...)
    return output
end


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
end

function pretty_print(geno::FunctionGraphGenotype)
    println("FunctionGraphGenotype:")
    println("  Input Nodes: ", join(geno.input_node_ids, ", "))
    println("  Bias Nodes: ", join(geno.bias_node_ids, ", "))
    println("  Hidden Nodes: ", join(geno.hidden_node_ids, ", "))
    println("  Output Nodes: ", join(geno.output_node_ids, ", "))

    println("\nNodes:")
    for (id, node) in geno.nodes
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
    n_input_nodes::Int
    n_bias_nodes::Int
    n_output_nodes::Int
end


function create_ids_and_nodes(
    genotype_creator::FunctionGraphGenotypeCreator, 
    gene_id_counter::Counter,
    function_symbol::Symbol,
)
    input_node_ids = next!(gene_id_counter, genotype_creator.n_input_nodes)
    input_nodes = Dict(
        id => FunctionGraphNode(
            id = id, 
            func = function_symbol, 
            input_connections = FunctionGraphConnection[]
        ) for id in input_node_ids
    )
    return input_node_ids, input_nodes
end

function create_output_ids_and_nodes(
    genotype_creator::FunctionGraphGenotypeCreator, 
    rng::AbstractRNG,
    gene_id_counter::Counter,
    input_node_ids::Vector{Int},
)
    output_node_ids = next!(gene_id_counter, genotype_creator.n_output_nodes)
    output_nodes = Dict(
        map(output_node_ids) do id
            input_connection_id = rand(rng, input_node_ids)[1]
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
    rng::AbstractRNG,
    gene_id_counter::Counter,
    n_pop::Int
)
    genotypes = FunctionGraphGenotype[]
    for _ in 1:n_pop
        input_node_ids, input_nodes = create_ids_and_nodes(
            genotype_creator, gene_id_counter, :INPUT
        )
        bias_node_ids, bias_nodes = create_ids_and_nodes(
            genotype_creator, gene_id_counter, :BIAS
        )
        available_input_ids = [input_node_ids; bias_node_ids]
        output_node_ids, output_nodes = create_output_ids_and_nodes(
            genotype_creator, rng, gene_id_counter, available_input_ids
        )

        nodes = merge(input_nodes, bias_nodes, output_nodes)
        genotype = FunctionGraphGenotype(
            input_node_ids = input_node_ids, 
            bias_node_ids = bias_node_ids,
            output_node_ids = output_node_ids, 
            hidden_node_ids = Int[], 
            nodes = nodes
        )
        push!(genotypes, genotype)
    end

    return genotypes
end
end