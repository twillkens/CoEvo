module LinearizedFunctionGraphs

export LinearizedFunctionGraphPhenotype, LinearizedFunctionGraphNode, LinearizedFunctionGraphConnection
export LinearizedFunctionGraphPhenotypeCreator

using ...Species.Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphNode, GraphFunction
using ...Species.Genotypes.FunctionGraphs: FunctionGraphConnection, FUNCTION_MAP, minimize
using ...Phenotypes.Abstract: Phenotype, PhenotypeCreator

import ...Phenotypes.Interfaces: create_phenotype, act!, reset!

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
        
        # Flatten all previous layers for easy membership checking
        flattened_previous_layers = vcat(layers...)
        
        # Find the nodes that use the current layer as inputs and meet all dependencies
        next_layer = Int[]
        for node_id in node_pool
            node = genotype.nodes[node_id]
            
            # Check if all input nodes of the current node are in the flattened previous layers
            input_node_ids = [
                input_connection.input_node_id 
                for input_connection in node.input_connections
                if !input_connection.is_recurrent
            ]
            
            # This node is valid if all of its input nodes are in the flattened previous layers
            # or if it has no nonrecurrent input nodes.
            # (This evaluates to `true` if the input_node_ids is empty)
            if all(in_id -> in_id in flattened_previous_layers, input_node_ids)
                push!(next_layer, node_id)
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


function initialize_linearized_nodes_from_genotype(geno::FunctionGraphGenotype)
    all_nodes = Dict(id => LinearizedFunctionGraphNode(node) for (id, node) in geno.nodes)
    for (id, node) in all_nodes
        node.input_nodes = [
            all_nodes[conn.input_node_id] => LinearizedFunctionGraphConnection(conn)
            for conn in geno.nodes[id].input_connections
        ]
        node.input_values = zeros(Float32, length(node.input_nodes))
    end
    return all_nodes
end

function create_phenotype(
    ::LinearizedFunctionGraphPhenotypeCreator, geno::FunctionGraphGenotype
)::LinearizedFunctionGraphPhenotype
    geno = minimize(geno)
    layers = construct_layers(geno)
    stateful_nodes = initialize_linearized_nodes_from_genotype(geno)
    
    ordered_nodes = vcat(layers...)
    nodes_in_order = [stateful_nodes[id] for id in ordered_nodes]
    output_nodes = [stateful_nodes[id] for id in geno.output_node_ids]
    output_values = zeros(Float32, length(output_nodes))

    phenotype = LinearizedFunctionGraphPhenotype(
        n_input_nodes = length(geno.input_node_ids),
        n_bias_nodes = length(geno.bias_node_ids),
        n_hidden_nodes = length(geno.hidden_node_ids),
        n_output_nodes = length(geno.output_node_ids),
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

# function act!(phenotype::LinearizedFunctionGraphPhenotype, input_values::Vector{Float32})
#     for node in phenotype.nodes
#         node.previous_value = node.current_value
#     end
# 
#     if any(isnan, input_values)
#         println("NaN input values: ", input_values)
#         println("Phenotype: ", phenotype)
#         throw(ErrorException("NaN input values"))
#     end
# 
#     @inbounds for (index, value) in enumerate(input_values)
#         phenotype.nodes[index].previous_value = value
#         phenotype.nodes[index].current_value = value
#     end
# 
#     hidden_node_start = phenotype.n_input_nodes + phenotype.n_bias_nodes + 1
# 
#     @inbounds for node in phenotype.nodes[hidden_node_start:end]
#         @inbounds for (index, input_node_connection) in enumerate(node.input_nodes)
#             input_node, connection = input_node_connection
#             value = connection.is_recurrent ? 
#                 input_node.previous_value : input_node.current_value
#             node.input_values[index] = connection.weight * value
#         end
# 
#         node_value = apply_func(node.func, node.input_values)
#         node.current_value = node_value
#     end
# 
#     @inbounds for (index, output_node) in enumerate(phenotype.output_nodes)
#         phenotype.output_values[index] = output_node.current_value
#     end
# 
#     output_values = phenotype.output_values
#     #output_values = [
#     #    phenotype.nodes[output_id].current_value for output_id in phenotype.output_node_ids
#     #]
#     return output_values
# end

function act!(phenotype::LinearizedFunctionGraphPhenotype, input_values::Vector{Float32})
    nodes = phenotype.nodes
    output_values = phenotype.output_values
    hidden_node_start = phenotype.n_input_nodes + phenotype.n_bias_nodes + 1

    for node in phenotype.nodes
        node.previous_value = node.current_value
    end

    if any(isnan, input_values)
        println("NaN input values: ", input_values)
        println("Phenotype: ", phenotype)
        throw(ErrorException("NaN input values"))
    end

    @inbounds begin
        for i in 1:length(input_values)
            node = nodes[i]
            node.previous_value = input_values[i]
            node.current_value = input_values[i]
        end

        for node in nodes[hidden_node_start:end]
            input_node_connections = node.input_nodes
            input_values_node = node.input_values

            for j in eachindex(input_node_connections)
                input_node, connection = input_node_connections[j]
                value = connection.is_recurrent ? 
                    input_node.previous_value : input_node.current_value
                input_values_node[j] = connection.weight * value
            end

            node.current_value = apply_func(node.func, input_values_node)
        end

        for i in 1:length(phenotype.output_nodes)
            output_values[i] = phenotype.output_nodes[i].current_value
        end
    end

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

end