module GnarlNetworks

export GnarlNetworkPhenotype, Neuron, Connection, GnarlNetworkPhenotypeCreator
export NodeOperation, create_phenotype, act!, reset!, get_output, set_output!
export scaled_tanh

import ....Interfaces: act!, reset!, create_phenotype
using ....Abstract

using ...Genotypes.GnarlNetworks
using ...Phenotypes.Defaults

struct Neuron
    position::Float32
    output::Base.RefValue{Float32}
end

function Neuron(position::Float32, output::Float32)
    Neuron(position, Ref(output))
end

function get_output(neuron::Neuron)
    neuron.output[]
end

function set_output!(neuron::Neuron, output::Float32)
    neuron.output[] = output
end

struct Connection
    input_node::Neuron
    weight::Float32
end

struct NodeOperation
    input_connections::Vector{Connection}
    output_node::Neuron
end

struct GnarlNetworkPhenotype <: Phenotype
    id::Int
    n_input_nodes::Int
    n_output_nodes::Int
    neurons::Dict{Float32, Neuron}
    operations::Vector{NodeOperation}
    hidden_function::Function
    output_function::Function
end

Base.@kwdef struct GnarlNetworkPhenotypeCreator <: PhenotypeCreator
    hidden_function::Function
    output_function::Function
end


function create_phenotype(
    phenotype_creator::GnarlNetworkPhenotypeCreator, id::Int, genotype::GnarlNetworkGenotype
)
    neuron_positions = get_neuron_positions(genotype)
    neurons = Dict(
        position => Neuron(position, 0.0f0)
        for position in neuron_positions
    )
    connection_map = Dict(
        position => filter(
            connection -> connection.destination == position, 
            genotype.connections
        ) 
        for position in neuron_positions
    )
    operations = [
        NodeOperation(
            [
                Connection(
                    neurons[connection.origin], connection.weight
                ) 
                for connection in connection_map[position]
            ], 
            neurons[position]
        ) 
        for position in neuron_positions
    ]
    phenotype = GnarlNetworkPhenotype(
        id, 
        genotype.n_input_nodes, 
        genotype.n_output_nodes, 
        neurons, 
        operations,
        phenotype_creator.hidden_function,
        phenotype_creator.output_function
    )
    return phenotype
end

function scaled_tanh(x::Float32)
    return tanh(2.5f0 * x)
end

function create_phenotype(::DefaultPhenotypeCreator, id::Int, genotype::GnarlNetworkGenotype)
    create_phenotype(GnarlNetworkPhenotypeCreator(scaled_tanh, scaled_tanh), id, genotype)
end

function reset!(phenotype::GnarlNetworkPhenotype)
    for neuron in values(phenotype.neurons)
        set_output!(neuron, 0.0f0)
    end
end

function act!(
    phenotype::GnarlNetworkPhenotype,
    inputs::Vector{Float32}
)
    if length(inputs) != phenotype.n_input_nodes
        throw(ArgumentError("Wrong number of inputs for $phenotype"))
    end
    operations = phenotype.operations
    for i in 1:phenotype.n_input_nodes
        set_output!(operations[i].output_node, inputs[i])
    end
    set_output!(operations[phenotype.n_input_nodes + 1].output_node, 1.0f0) # Bias
    start_operation_idx = phenotype.n_input_nodes + 2
    for operation in operations[start_operation_idx:end]
        sum = 0.0f0
        for i = eachindex(operation.input_connections)
            input_connection = operation.input_connections[i]
            connection_output = get_output(input_connection.input_node) * input_connection.weight
            sum += connection_output
        end
        if operation.output_node.position < 1.0f0
            set_output!(operation.output_node, phenotype.hidden_function(sum))
        else
            set_output!(operation.output_node, phenotype.output_function(sum))
        end
        #set_output!(operation.output_node, tanh(2.5f0 * sum))
    end
    outputs = [
        get_output(operations[end - phenotype.n_output_nodes + i].output_node) 
        for i in 1:phenotype.n_output_nodes
    ]
    return outputs
end
#function act_messed_up!(
#    phenotype::GnarlNetworkPhenotype,
#    inputs::Vector{Float32}
#)
#    if length(inputs) != phenotype.n_input_nodes
#        throw(ArgumentError("Wrong number of inputs for $phenotype"))
#    end
#    operations = phenotype.operations
#    for i in 1:phenotype.n_input_nodes
#        set_output!(operations[i].output_node, inputs[i])
#    end
#    set_output!(operations[phenotype.n_input_nodes + 1].output_node, 1.0f0) # Bias
#    start_operation_idx = phenotype.n_input_nodes + 2
#    for operation in operations[start_operation_idx:end - phenotype.n_output_nodes]
#        output_sum = 0.0f0
#        for i = eachindex(operation.input_connections)
#            input_connection = operation.input_connections[i]
#            connection_output = get_output(input_connection.input_node) * input_connection.weight
#            output_sum += connection_output
#        end
#        println("output_sum = $output_sum")
#        set_output!(operation.output_node, phenotype.hidden_function(output_sum))
#    end
#    outputs = [
#        phenotype.output_function(get_output(operations[end - phenotype.n_output_nodes + i].output_node))
#        for i in 1:phenotype.n_output_nodes
#    ]
#    println("outputs = $outputs")
#    return outputs
#end

act!(phenotype::GnarlNetworkPhenotype, inputs::Vector{Float64}) = act!(phenotype, Float32.(inputs))

act!(phenotype::GnarlNetworkPhenotype, input::Real) = act!(phenotype, [input])

end
#function Base.show(io::IO, neuron::Neuron)
#    println(io, "Neuron(Position: $(neuron.position), Output: $(get_output(neuron)))")
#end
#
#function Base.show(io::IO, conn::Connection)
#    println(io, "Connection(InputNode Position: $(conn.input_node.position), Weight: $(conn.weight))")
#end
#
#function Base.show(io::IO, op::NodeOperation)
#    println(io, "Node Operation(OutputNode Position: $(op.output_node.position), #Connections: $(length(op.input_connections)))")
#end
#
#function Base.show(io::IO, phenotype::GnarlNetworkPhenotype)
#    println(io, "GnarlNetwork Phenotype(#Input Nodes: $(phenotype.n_input_nodes), #Output Nodes: $(phenotype.n_output_nodes), #Neurons: $(length(phenotype.neurons)), #Operations: $(length(phenotype.operations)))")
#end