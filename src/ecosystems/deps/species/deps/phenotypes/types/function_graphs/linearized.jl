module LinearizedFunctionGraphs

export LinearizedFunctionGraphPhenotype, LinearizedFunctionGraphNode, LinearizedFunctionGraphConnection
export LinearizedFunctionGraphPhenotypeCreator

using ...Species.Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphNode, GraphFunction
using ...Species.Genotypes.FunctionGraphs: FunctionGraphConnection, FUNCTION_MAP, minimize
using ...Species.Genotypes.FunctionGraphs: evaluate
using ...Phenotypes.Abstract: Phenotype, PhenotypeCreator

import ...Phenotypes.Interfaces: create_phenotype, act!, reset!

struct LinearizedFunctionGraphPhenotypeCreator <: PhenotypeCreator end

Base.@kwdef struct LinearizedFunctionGraphConnection
    input_node_index::Int
    weight::Float32
    is_recurrent::Bool
end

@kwdef mutable struct LinearizedFunctionGraphNode{G <: GraphFunction}
    id::Int
    func::G
    current_value::Float32 = 0.0f0
    previous_value::Float32 = 0.0f0
    input_connections::Vector{LinearizedFunctionGraphConnection}
    input_values::Vector{Float32}
end

@kwdef struct LinearizedFunctionGraphPhenotype <: Phenotype
    n_input_nodes::Int
    n_bias_nodes::Int
    n_hidden_nodes::Int
    n_output_nodes::Int
    nodes::Vector{LinearizedFunctionGraphNode}
    output_node_indices::Vector{Int}
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

function create_node_id_to_position_dict(ordered_node_ids::Vector{Int})
    return Dict(id => idx for (idx, id) in enumerate(ordered_node_ids))
end


function make_linearized_nodes(
    geno::FunctionGraphGenotype, 
    ordered_node_ids::Vector{Int}, 
    node_id_to_position_dict::Dict{Int, Int}
)
    linearized_nodes = map(ordered_node_ids) do id
        node = geno.nodes[id]
        func = FUNCTION_MAP[node.func]
        previous_value = func.name == :BIAS ? 1.0f0 : 0.0f0
        current_value = previous_value
        connections = LinearizedFunctionGraphConnection[
            LinearizedFunctionGraphConnection(
                input_node_index = node_id_to_position_dict[connection.input_node_id],
                weight = connection.weight,
                is_recurrent = connection.is_recurrent
            )
            for connection in node.input_connections
        ]
        input_values = zeros(Float32, length(connections))
        linearized_node = LinearizedFunctionGraphNode(
            id = id,
            func = func,
            previous_value = previous_value,
            current_value = current_value,
            input_connections = connections,
            input_values = input_values
        )
        return linearized_node
    end
    return linearized_nodes
end

function create_phenotype(
    ::LinearizedFunctionGraphPhenotypeCreator, geno::FunctionGraphGenotype
)::LinearizedFunctionGraphPhenotype
    geno = minimize(geno)
    layers = construct_layers(geno)
    ordered_node_ids = vcat(layers...)
    node_id_to_position_dict = create_node_id_to_position_dict(ordered_node_ids)
    linearized_nodes = make_linearized_nodes(geno, ordered_node_ids, node_id_to_position_dict)
    output_node_indices = [node_id_to_position_dict[id] for id in geno.output_node_ids]
    output_values = zeros(Float32, length(geno.output_node_ids))

    phenotype = LinearizedFunctionGraphPhenotype(
        n_input_nodes = length(geno.input_node_ids),
        n_bias_nodes = length(geno.bias_node_ids),
        n_hidden_nodes = length(geno.hidden_node_ids),
        n_output_nodes = length(geno.output_node_ids),
        nodes = linearized_nodes,
        output_node_indices = output_node_indices,
        output_values = output_values
    )
    return phenotype
end

function apply_func(node_func::GraphFunction, input_values::Vector{Float32})::Float32
    # Specific function applications for known arities
end


function act!(phenotype::LinearizedFunctionGraphPhenotype, input_values::Vector{Float32})
    if any(isnan, input_values)
        println("NaN input values: ", input_values)
        println("Phenotype: ", phenotype)
        throw(ErrorException("NaN input values"))
    end

    @inbounds begin
        hidden_nodes_end_index = phenotype.n_input_nodes + 
            phenotype.n_bias_nodes + phenotype.n_hidden_nodes
        for node in phenotype.nodes[1:hidden_nodes_end_index]
            node.previous_value = node.current_value
        end
        for i in 1:length(input_values)
            node = phenotype.nodes[i]
            node.current_value = input_values[i]
        end

        hidden_node_start = phenotype.n_input_nodes + phenotype.n_bias_nodes + 1
        for node in phenotype.nodes[hidden_node_start:end]
            for input_index in eachindex(node.input_connections)
                connection = node.input_connections[input_index]
                input_node = phenotype.nodes[connection.input_node_index]
                value = connection.is_recurrent ? 
                    input_node.previous_value : input_node.current_value
                node.input_values[input_index] = connection.weight * value
            end
            node.current_value = evaluate(node.func, node.input_values)
            #node_func = node.func
            #if node_func.arity == 1
            #    node.current_value = evaluate(node_func, node.input_values[1])::Float32
            #elseif node_func.arity == 2
            #    node.current_value = evaluate(
            #        node_func, node.input_values[1], node.input_values[2])::Float32
            #else
            #    throw(ErrorException("Unsupported arity: $(node_func.arity)"))
            #end
        end

        for output_index in eachindex(phenotype.output_node_indices)
            output_node_index = phenotype.output_node_indices[output_index]
            output_node = phenotype.nodes[output_node_index]
            phenotype.output_values[output_index] = output_node.current_value
        end
    end
    #for node in phenotype.nodes
    #    node.previous_value = node.current_value
    #end


    output_values = phenotype.output_values
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