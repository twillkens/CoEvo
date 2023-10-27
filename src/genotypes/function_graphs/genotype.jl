export FunctionGraphGenotype, FunctionGraphGenotypeCreator
export FunctionGraphConnection, FunctionGraphNode
export create_genotypes, create_ids_and_nodes, create_output_ids_and_nodes

"""
    FunctionGraphConnection

Represents a connection in a function graph. It defines an input node via its ID, 
a weight for the connection, and a flag indicating if the connection is recurrent.
"""
@kwdef mutable struct FunctionGraphConnection
    input_node_id::Int
    weight::Float64
    is_recurrent::Bool
end

"""
    FunctionGraphNode

Represents a node in a function graph. Each node has a unique ID, a function (represented 
by a symbol), and a list of input connections (`FunctionGraphConnection`).
"""
@kwdef struct FunctionGraphNode
    id::Int
    func::Symbol
    input_connections::Vector{FunctionGraphConnection}
end

"""
    FunctionGraphGenotype

Defines the genotype for a function graph. This genotype contains nodes segregated 
into input, bias, hidden, and output categories. Additionally, a dictionary (`nodes`) 
maps node IDs to their corresponding `FunctionGraphNode` structures.
"""
@kwdef struct FunctionGraphGenotype <: Genotype
    input_node_ids::Vector{Int}
    bias_node_ids::Vector{Int}
    hidden_node_ids::Vector{Int}
    output_node_ids::Vector{Int}
    nodes::Dict{Int, FunctionGraphNode}
    n_nodes_per_output::Int
end

"""
    FunctionGraphGenotypeCreator

Structure to facilitate the creation of `FunctionGraphGenotype`. It specifies the 
number of inputs, biases, outputs, and nodes associated with each output.
"""
@kwdef struct FunctionGraphGenotypeCreator <: GenotypeCreator
    n_inputs::Int
    n_bias::Int
    n_outputs::Int
    n_nodes_per_output::Int
end


"""
    create_ids_and_nodes(gene_id_counter::Counter, function_symbol::Symbol, n_nodes::Int)

Create a set of node IDs and their corresponding `FunctionGraphNode` instances, given 
a function symbol and the desired number of nodes.
"""
function create_ids_and_nodes(
    gene_id_counter::Counter,
    function_symbol::Symbol,
    n_nodes::Int
)
    node_ids = count!(gene_id_counter, n_nodes)
    nodes = Dict(
        id => FunctionGraphNode(
            id = id, 
            func = function_symbol, 
            input_connections = FunctionGraphConnection[]
        ) for id in node_ids
    )
    return node_ids, nodes
end

"""
    create_output_ids_and_nodes(genotype_creator, random_number_generator, gene_id_counter, input_node_ids)

Given a genotype creator and some input node IDs, generates output node IDs 
and their associated `FunctionGraphNode` instances.
"""
function create_output_ids_and_nodes(
    genotype_creator::FunctionGraphGenotypeCreator, 
    random_number_generator::AbstractRNG,
    gene_id_counter::Counter,
    input_node_ids::Vector{Int},
)
    n_output_nodes = genotype_creator.n_outputs * genotype_creator.n_nodes_per_output
    output_node_ids = count!(gene_id_counter, n_output_nodes)
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
