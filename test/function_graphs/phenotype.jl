using CoEvo
using .Phenotypes.FunctionGraphs: init_stateful_nodes_from_genotype
using DataStructures: OrderedDict
using Test

import .Phenotypes.Interfaces: create_phenotype, act!, reset!

STOP = false
struct LinearizedFunctionGraphPhenotypeCreator <: PhenotypeCreator end


Base.@kwdef struct LinearizedFunctionGraphConnection
    input_node_id::Int
    weight::Float32
    is_recurrent::Bool
end

function LinearizedFunctionGraphConnection(connection::FunctionGraphConnection)
    return LinearizedFunctionGraphConnection(
        input_node_id = connection.input_node_id,
        weight = Float32(connection.weight),
        is_recurrent = connection.is_recurrent
    )
end

@kwdef mutable struct LinearizedFunctionGraphNode
    id::Int
    func::GraphFunction
    current_value::Float32 = 0.0f0
    previous_value::Float32 = 0.0f0
    input_nodes::Vector{Pair{LinearizedFunctionGraphNode, LinearizedFunctionGraphConnection}}
    input_values::Vector{Float32}
end

function LinearizedFunctionGraphNode(stateless_node::FunctionGraphNode)
    func = FUNCTION_MAP[stateless_node.func]
    previous_value = func.name == :BIAS ? 1.0f0 : 0.0f0
    current_value = previous_value
    return LinearizedFunctionGraphNode(
        id = stateless_node.id,
        func = func,
        current_value = current_value,
        previous_value = previous_value,
        input_nodes = Pair{LinearizedFunctionGraphNode, LinearizedFunctionGraphConnection}[],
        input_values = zeros(Float32, func.arity)
    )
end

@kwdef struct LinearizedFunctionGraphPhenotype <: Phenotype
    n_input_nodes::Int
    n_bias_nodes::Int
    n_hidden_nodes::Int
    n_output_nodes::Int
    nodes::Vector{LinearizedFunctionGraphNode}
    output_nodes::Vector{LinearizedFunctionGraphNode}
    output_values::Vector{Float32}
end

function sort_layer(node_ids::Vector{Int}, genotype::FunctionGraphGenotype)::Vector{Int}
    # Define a helper function to determine if node B has a nonrecurrent connection to node A
    has_nonrecurrent_connection(A::Int, B::Int) = any(
        conn -> conn.input_node_id == B && !conn.is_recurrent, 
        genotype.nodes[A].input_connections
    )

    # Sort the node_ids based on the helper function
    sort!(node_ids, by = A -> sum(has_nonrecurrent_connection(A, B) for B in node_ids))

    return node_ids
end

function construct_layers(genotype::FunctionGraphGenotype)::Vector{Vector{Int}}
    layers = Vector{Vector{Int}}()
    
    # Initialize pool with all nodes except the input nodes
    first_layer = [genotype.input_node_ids ; genotype.bias_node_ids]
    node_pool = Set(keys(genotype.nodes))
    setdiff!(node_pool, first_layer)
    
    current_layer = first_layer

    while !isempty(current_layer)
        # Add the current layer to layers
        push!(layers, current_layer)
        
        # Find the nodes that use the current layer as inputs
        next_layer = Int[]
        for node_id in node_pool
            node = genotype.nodes[node_id]
            for input_connection in node.input_connections
                input_node_id = input_connection.input_node_id
                if input_node_id in current_layer
                    push!(next_layer, node_id)
                    break  # Move to the next node in the pool after finding a valid connection
                end
            end
        end

        # Remove the nodes in the next_layer from the pool
        setdiff!(node_pool, next_layer)

        # Sort the next layer
        next_layer = sort_layer(next_layer, genotype)

        # Set the next layer as the current layer for the next iteration
        current_layer = next_layer
    end

    return layers
end

function initialize_linearized_nodes_from_genotype(genotype::FunctionGraphGenotype)
    all_nodes = Dict(id => LinearizedFunctionGraphNode(node) for (id, node) in genotype.nodes)
    for (id, node) in all_nodes
        node.input_nodes = [
            all_nodes[conn.input_node_id] => LinearizedFunctionGraphConnection(conn)
            for conn in genotype.nodes[id].input_connections
        ]
        node.input_values = zeros(Float32, length(node.input_nodes))
    end
    return all_nodes
end

function create_phenotype(
    ::LinearizedFunctionGraphPhenotypeCreator, genotype::FunctionGraphGenotype
)::LinearizedFunctionGraphPhenotype
    layers = construct_layers(genotype)
    stateful_nodes = initialize_linearized_nodes_from_genotype(genotype)
    
    ordered_nodes = vcat(layers...)
    nodes_in_order = [stateful_nodes[id] for id in ordered_nodes]
    output_nodes = [stateful_nodes[id] for id in genotype.output_node_ids]
    output_values = zeros(Float32, length(output_nodes))

    phenotype = LinearizedFunctionGraphPhenotype(
        n_input_nodes = length(genotype.input_node_ids),
        n_bias_nodes = length(genotype.bias_node_ids),
        n_hidden_nodes = length(genotype.hidden_node_ids),
        n_output_nodes = length(genotype.output_node_ids),
        nodes = nodes_in_order,
        output_nodes = output_nodes,
        output_values = output_values
    )
    return phenotype
end

function apply_func(node_func::GraphFunction, input_values::Vector{Float32})::Float32
    # Specific function applications for known arities
    if node_func.arity == 1
        value = node_func.func(input_values[1])::Float32
        #if typeof(value) !== Float32
        #    throw(ErrorException("Function $(node_func.name) returned $(typeof(value)) instead of Float32"))
        #end
        return value
    elseif node_func.arity == 2
        value = node_func.func(input_values[1], input_values[2])::Float32
        #if typeof(value) !== Float32
        #    throw(ErrorException("Function $(node_func.name) returned $(typeof(value)) instead of Float32"))
        #end
        return value
    # Additional cases here...
    else
        throw(ErrorException("Unsupported arity: $(node_func.arity)"))
    end
end

function act!(phenotype::LinearizedFunctionGraphPhenotype, input_values::Vector{Float32})
    for node in phenotype.nodes
        node.previous_value = node.current_value
    end

    if any(isnan, input_values)
        println("NaN input values: ", input_values)
        println("Phenotype: ", phenotype)
        throw(ErrorException("NaN input values"))
    end

    @inbounds for (index, value) in enumerate(input_values)
        phenotype.nodes[index].current_value = value
    end

    hidden_node_start = phenotype.n_input_nodes + phenotype.n_bias_nodes + 1

    @inbounds for node in phenotype.nodes[hidden_node_start:end]
        for (index, input_node_connection) in enumerate(node.input_nodes)
            input_node, connection = input_node_connection
            value = connection.is_recurrent ? 
                input_node.previous_value : input_node.current_value
            node.input_values[index] = connection.weight * value
        end

        node_value = apply_func(node.func, node.input_values)
        node.current_value = node_value
    end

    @inbounds for (index, output_node) in enumerate(phenotype.output_nodes)
        phenotype.output_values[index] = output_node.current_value
    end

    output_values = phenotype.output_values
    #output_values = [
    #    phenotype.nodes[output_id].current_value for output_id in phenotype.output_node_ids
    #]
    return output_values
end

function act!(phenotype::LinearizedFunctionGraphPhenotype, input_values::Vector{Float64})
    output_values = act!(phenotype, Float32.(input_values))
    return output_values
end

function reset!(phenotype::LinearizedFunctionGraphPhenotype)
    for node in values(phenotype.nodes)
        node.current_value = 0.0f0
        node.previous_value = 0.0f0
    end
end

genotype = FunctionGraphGenotype(
    input_node_ids = [0],
    bias_node_ids = Int[],
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
            FunctionGraphConnection(1, 1.0, false),
            FunctionGraphConnection(5, 1.0, true), 
        ]),
        2 => FunctionGraphNode(2, :IDENTITY, [
            FunctionGraphConnection(1, 1.0, true)
        ]),
        1 => FunctionGraphNode(1, :IDENTITY, [
            FunctionGraphConnection(0, 1.0, false)
        ]),
        0 => FunctionGraphNode(0, :INPUT, [])
    )
)

layers = construct_layers(genotype)
println("layers: ", layers)

phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
phenotype = create_phenotype(phenotype_creator, genotype)
# # println("phenotype: ", phenotype)
# 
# #println("phenotype: ", phenotype)
current_values = [node.current_value for node in phenotype.nodes]
@test current_values == Float32.([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

input_values = [1.0]
output = act!(phenotype, input_values)
@test output == [1.0]
# 
current_values = [node.current_value for node in phenotype.nodes]
@test current_values == Float32.([1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0])
# 
output = act!(phenotype, input_values)
@test output == [1.0]
current_values = [node.current_value for node in phenotype.nodes]
@test current_values == Float32.([1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0])
# 
output = act!(phenotype, input_values)
current_values = [node.current_value for node in phenotype.nodes]
@test current_values == Float32.([1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 2.0])
@test output == [2.0]
STOP = true
output = act!(phenotype, input_values)
println("output: ", output)
@test output == [3.0]
output = act!(phenotype, input_values)
println("output: ", output)
@test output == [5.0]
output = act!(phenotype, input_values)
println("output: ", output)
@test output == [8.0]
output = act!(phenotype, input_values)
println("output: ", output)
@test output == [13.0]

using BenchmarkTools

# Define the function for the LinearizedFunctionGraphPhenotypeCreator representation
function fibonacci_linearized(phenotype::Phenotype, input_values::Vector{Float32})
    reset!(phenotype)
    for _ in 1:50  # Run fibonacci sequence 10 times for demonstration
        act!(phenotype, input_values)
    end
end

# This assumes you've loaded your genotype `genotype` and created the phenotype `phenotype` as in your code above
phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
phenotype = create_phenotype(phenotype_creator, genotype)

# Benchmark the LinearizedFunctionGraphPhenotypeCreator representation
linearized_benchmark = @benchmark fibonacci_linearized($phenotype, [1.0f0])

# Display the benchmark result
println(linearized_benchmark)
#
phenotype_creator = DefaultPhenotypeCreator()
phenotype = create_phenotype(phenotype_creator, genotype)

# Benchmark the LinearizedFunctionGraphPhenotypeCreator representation
linearized_benchmark = @benchmark fibonacci_linearized($phenotype, [1.0f0])

# Display the benchmark result
println(linearized_benchmark)