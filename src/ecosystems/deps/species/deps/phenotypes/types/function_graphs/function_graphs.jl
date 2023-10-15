module FunctionGraphs

export FunctionGraphPhenotype, FunctionGraphStatefulNode

using ...Species.Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphNode
using ...Species.Genotypes.FunctionGraphs: FunctionGraphConnection, FUNCTION_MAP
using ...Phenotypes.Abstract: Phenotype, PhenotypeCreator

import ...Phenotypes.Interfaces: create_phenotype, act!, reset!

@kwdef mutable struct FunctionGraphStatefulNode
    id::Int
    func::Symbol
    current_value::Union{Float64, Nothing} = nothing
    previous_value::Float64 = 0.0
    input_nodes::Vector{Pair{FunctionGraphStatefulNode, FunctionGraphConnection}}
    seeking_output::Bool = false
end

function pretty_print(node::FunctionGraphStatefulNode; visited=Set{Int}(), indent="")
    println("$(indent)Node ID: ", node.id)
    println("$(indent)  Function: ", node.func)
    println("$(indent)  Current Value: ", node.current_value)
    println("$(indent)  Previous Value: ", node.previous_value)
    println("$(indent)  Seeking Output: ", node.seeking_output ? "Yes" : "No")
    println("$(indent)  Connected Input Nodes:")
    
    # Avoiding infinite loop by checking visited nodes
    push!(visited, node.id)
    
    for (input_node, connection) in node.input_nodes
        if input_node.id in visited
            println("$(indent)    Node ID: ", input_node.id, " [Visited]")
        else
            println("$(indent)    Node ID: ", input_node.id)
            println("$(indent)      Connection Weight: ", connection.weight)
            println("$(indent)      Is Recurrent: ", connection.is_recurrent ? "Yes" : "No")
            pretty_print(input_node, visited=visited, indent=indent * "  ")
        end
    end
end


@kwdef struct FunctionGraphPhenotype <: Phenotype
    input_node_ids::Vector{Int}
    bias_node_ids::Vector{Int}
    hidden_node_ids::Vector{Int}
    output_node_ids::Vector{Int}
    nodes::Dict{Int, FunctionGraphStatefulNode}
end

function FunctionGraphStatefulNode(stateless_node::FunctionGraphNode)
    return FunctionGraphStatefulNode(
        id = stateless_node.id,
        func = stateless_node.func,
        input_nodes = Pair{FunctionGraphStatefulNode, FunctionGraphConnection}[]
    )
end

function init_stateful_nodes_from_genotype(geno::FunctionGraphGenotype)
    all_nodes = Dict(id => FunctionGraphStatefulNode(node) for (id, node) in geno.nodes)
    for (id, node) in all_nodes
        node.input_nodes = [
            all_nodes[conn.input_node_id] => conn
            for conn in geno.nodes[id].input_connections
        ]
    end
    return all_nodes
end

function create_phenotype(
    ::PhenotypeCreator, geno::FunctionGraphGenotype
)::FunctionGraphPhenotype
    stateful_nodes = init_stateful_nodes_from_genotype(geno)
    phenotype = FunctionGraphPhenotype(
        input_node_ids = geno.input_node_ids, 
        bias_node_ids = geno.bias_node_ids,
        hidden_node_ids = geno.hidden_node_ids,
        output_node_ids = geno.output_node_ids, 
        nodes = stateful_nodes
    )
    return phenotype
end

function print_phenotype_state(phenotype::FunctionGraphPhenotype)
    sorted_nodes = sort(collect(values(phenotype.nodes)), by = node -> node.id)
    println("IDENTITY\tPrevious Value\tCurrent Value")
    for node in sorted_nodes
        println("$(node.id)\t$(node.previous_value)\t$(node.current_value)")
    end
end


function get_output!(node::FunctionGraphStatefulNode, is_recurrent_edge::Bool)
    #println("------------------------")
    #pretty_print(node)
    if node.func == :INPUT
        return node.current_value
    elseif node.seeking_output
        return is_recurrent_edge ? node.previous_value : node.current_value
    end
    node.seeking_output = true
    if node.current_value === nothing
        input_values = [
            get_output!(input_node, conn.is_recurrent) * conn.weight
            for (input_node, conn) in node.input_nodes
        ]
        node_function = FUNCTION_MAP[node.func]  # Ensure FUNCTION_MAP is defined elsewhere
        output_value = node_function(input_values...)
        node.current_value = output_value
    end
    output_value = is_recurrent_edge ? node.previous_value : node.current_value
    if output_value === nothing
        println("Node $(node.id) has no output value")
        println("Node $(node.id) is recurrent: $(is_recurrent_edge)")
        println("Node $(node.id) function: $(node.func)")
        println("Node $(node.id) input nodes: $(node.input_nodes)")
        println("Node $(node.id) current value: $(node.current_value)")
        println("Node $(node.id) previous value: $(node.previous_value)")

        throw(ErrorException("Output value is still nothing after computation"))
    end
    node.seeking_output = false
    return output_value
end

function act!(phenotype::FunctionGraphPhenotype, input_values::Vector{T}) where T<:Real
    # Update previous_values before the new round of computation
    input_values = Float64.(input_values)
    for node in values(phenotype.nodes)
        node.previous_value = node.current_value === nothing ? 
            node.previous_value : node.current_value
        node.current_value = nothing
    end

    for (index, input_value) in enumerate(input_values)
        input_node = phenotype.nodes[phenotype.input_node_ids[index]]
        input_node.current_value = input_value
    end

    #print_phenotype_state(phenotype)
    output_values = Float64[]
    for output_node_id in phenotype.output_node_ids
        output_node = phenotype.nodes[output_node_id]
        output_value = get_output!(output_node, false)
        push!(output_values, output_value)
    end
    return T.(output_values)
end

function reset!(phenotype::FunctionGraphPhenotype)
    for node in values(phenotype.nodes)
        node.current_value = nothing
        node.previous_value = 0.0
    end
end

end
