module Basic

export BasicFunctionGraphPhenotype, FunctionGraphStatefulNode

import ...Phenotypes: create_phenotype, act!, reset!

using ....Genotypes: minimize
using ....Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphNode, GraphFunction
using ....Genotypes.FunctionGraphs: FunctionGraphConnection, FUNCTION_MAP, evaluate
using ....Phenotypes: Phenotype, PhenotypeCreator

Base.@kwdef struct FunctionGraphSmallConnection
    input_node_id::Int
    weight::Float32
    is_recurrent::Bool
end

function FunctionGraphSmallConnection(conn::FunctionGraphConnection)
    return FunctionGraphSmallConnection(
        input_node_id = conn.input_node_id,
        weight = Float32(conn.weight),
        is_recurrent = conn.is_recurrent
    )
end

@kwdef mutable struct FunctionGraphStatefulNode
    id::Int
    #func::Symbol
    func::GraphFunction
    current_value::Float32 = 0.0f0
    previous_value::Float32 = 0.0f0
    input_nodes::Vector{Pair{FunctionGraphStatefulNode, FunctionGraphSmallConnection}}
    seeking_output::Bool = false
    current_value_set::Bool = false
    input_values::Vector{Float32}
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


@kwdef struct BasicFunctionGraphPhenotype <: Phenotype
    input_node_ids::Vector{Int}
    bias_node_ids::Vector{Int}
    hidden_node_ids::Vector{Int}
    output_node_ids::Vector{Int}
    nodes::Dict{Int, FunctionGraphStatefulNode}
end

function FunctionGraphStatefulNode(stateless_node::FunctionGraphNode)
    return FunctionGraphStatefulNode(
        id = stateless_node.id,
        func = FUNCTION_MAP[stateless_node.func],
        input_nodes = Pair{FunctionGraphStatefulNode, FunctionGraphSmallConnection}[],
        input_values = Float32[]
    )
end

function init_stateful_nodes_from_genotype(genotype::FunctionGraphGenotype)
    all_nodes = Dict(id => FunctionGraphStatefulNode(node) for (id, node) in genotype.nodes)
    for (id, node) in all_nodes
        node.input_nodes = [
            all_nodes[conn.input_node_id] => FunctionGraphSmallConnection(conn)
            for conn in genotype.nodes[id].input_connections
        ]
        node.input_values = zeros(Float32, length(node.input_nodes))
    end
    return all_nodes
end

function create_phenotype(::PhenotypeCreator, genotype::FunctionGraphGenotype)
    stateful_nodes = init_stateful_nodes_from_genotype(genotype)
    phenotype = BasicFunctionGraphPhenotype(
        input_node_ids = genotype.input_node_ids, 
        bias_node_ids = genotype.bias_node_ids,
        hidden_node_ids = genotype.hidden_node_ids,
        output_node_ids = genotype.output_node_ids, 
        nodes = stateful_nodes
    )
    return phenotype
end

function print_phenotype_state(phenotype::BasicFunctionGraphPhenotype)
    sorted_nodes = sort(collect(values(phenotype.nodes)), by = node -> node.id)
    println("IDENTITY\tPrevious Value\tCurrent Value")
    for node in sorted_nodes
        println("$(node.id)\t$(node.previous_value)\t$(node.current_value)")
    end
end

function apply_func(node_func::GraphFunction, input_values::Vector{Float32})::Float32
    # Specific function applications for known arities
    if node_func.arity == 1
        value = evaluate(node_func, input_values[1])::Float32
        if typeof(value) !== Float32
            throw(ErrorException("Function $(node_func.name) returned $(typeof(value)) instead of Float32"))
        end
        return value
    elseif node_func.arity == 2
        value = evaluate(node_func, input_values[1], input_values[2])::Float32
        if typeof(value) !== Float32
            throw(ErrorException("Function $(node_func.name) returned $(typeof(value)) instead of Float32"))
        end
        return value
    # Additional cases here...
    else
        throw(ErrorException("Unsupported arity: $(node_func.arity)"))
    end
end

function get_output!(node::FunctionGraphStatefulNode, is_recurrent_edge::Bool)::Float32
    #println("------------------------")
    #pretty_print(node)
    if node.func.name == :INPUT
        return node.current_value
    elseif node.func.name == :BIAS
        return 1.0f0
    elseif node.seeking_output
        return is_recurrent_edge ? node.previous_value : node.current_value
    end
    node.seeking_output = true
    if !node.current_value_set
        for (index, input_node_conn) in enumerate(node.input_nodes)
            input_node, conn = input_node_conn
            input_value = get_output!(input_node, conn.is_recurrent) * conn.weight
            if isnan(input_value)
                println("Node ID: ", node.id)
                println("Node: ", node)
                println("Function: ", node.func)
                println("Input Node ID: ", input_node.id)
                println("Input Node: ", input_node)
                println("Input Value: ", input_value)
                throw(ErrorException("Input value is NaN"))
            end
            node.input_values[index] = input_value
        end
        #output_value = node.func(node.input_values...)
        output_value = apply_func(node.func, node.input_values)
        node.current_value = output_value
        node.current_value_set = true
    end
    output_value = is_recurrent_edge ? node.previous_value : node.current_value
    if output_value === nothing
        throw(ErrorException("Output value is still nothing after computation"))
    end
    if isnan(output_value)
        println("Node ID: ", node.id)
        println("Function: ", node.func)
        println("Input Values: ", node.input_values)
        println("Output Value: ", output_value)
        throw(ErrorException("Output value is NaN after computation"))
    end
    node.seeking_output = false
    return output_value
end

function act!(phenotype::BasicFunctionGraphPhenotype, input_values::Vector{Float32})
    # Update previous_values before the new round of computation
    for node in values(phenotype.nodes)
        node.previous_value = !node.current_value_set ? 
            node.previous_value : node.current_value
        node.current_value_set = false
    end

    if any(isnan, input_values)
        println("NaN input values: ", input_values)
        println("Phenotype: ", phenotype)
        throw(ErrorException("NaN input values"))
    end

    for (index, input_value) in enumerate(input_values)
        input_node = phenotype.nodes[phenotype.input_node_ids[index]]
        input_node.current_value = input_value
    end

    #print_phenotype_state(phenotype)
    output_values = Float32[]
    for output_node_id in phenotype.output_node_ids
        output_node = phenotype.nodes[output_node_id]
        output_value = get_output!(output_node, false)
        push!(output_values, output_value)
    end

    if any(isnan, output_values)
        println("NaN output values: ", output_values)
        println("Phenotype: ", phenotype)
        throw(ErrorException("NaN output values"))
    end
    return output_values
end

act!(phenotype::BasicFunctionGraphPhenotype, input_values::Vector{Float64}) = 
    act!(phenotype, Float32.(input_values))

function reset!(phenotype::BasicFunctionGraphPhenotype)
    for node in values(phenotype.nodes)
        node.current_value = 0.0
        node.previous_value = 0.0
        node.seeking_output = false
        node.current_value_set = false
    end
end

end
