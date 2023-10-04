module GnarlNetworks

export mutate_weight, GnarlNetworkMutator, mutate_weights, add_node, remove_node
export add_connection, remove_connection

using StatsBase: Weights, sample
using ....Species.Genotypes.Abstract: Genotype
using Random: AbstractRNG, shuffle!
using .....Ecosystems.Utilities.Counters: Counter, next!
using  ...Mutators.Abstract: Mutator
using ....Genotypes.GnarlNetworks: GnarlNetworkGenotype, GnarlNetworkConnectionGene, GnarlNetworkNodeGene
import ...Mutators.Interfaces: mutate


"Mutate the weight of genes"
function mutate_weight(
    rng::AbstractRNG, connection::GnarlNetworkConnectionGene, weight_factor::Float64
)
    connection = GnarlNetworkConnectionGene(
        connection.id, 
        connection.origin, 
        connection.destination, 
        connection.weight + randn(rng) * weight_factor, 
    )
    return connection
end

function mutate_weights(rng::AbstractRNG, geno::GnarlNetworkGenotype, weight_factor::Float64)
    connections = mutate_weight.(rng, geno.connections, weight_factor)
    geno = GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, geno.hidden_nodes,  connections
    )
    return geno
end

function add_node(geno::GnarlNetworkGenotype, gene_id::Int, position::Float32)
    node = GnarlNetworkNodeGene(gene_id, position)
    hidden_nodes = [geno.hidden_nodes; node]
    genotype = GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, hidden_nodes, geno.connections
    )
    return genotype
end

function add_node(rng::AbstractRNG, gene_id_counter::Counter, geno::GnarlNetworkGenotype)
    gene_id = next!(gene_id_counter)
    position = Float32(rand(rng))
    geno = add_node(geno, gene_id, position)
    return geno
end

function remove_node(geno::GnarlNetworkGenotype, node_to_remove::GnarlNetworkNodeGene)
    remaining_nodes = filter(x -> x != node_to_remove, geno.hidden_nodes)
    geno = GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, remaining_nodes, geno.connections
    )
    return geno
end

function remove_node(rng::AbstractRNG, ::Counter, geno::GnarlNetworkGenotype)
    if length(geno.hidden_nodes) == 0
        return geno
    end
    node_to_remove = rand(rng, geno.hidden_nodes)
    geno = remove_node(geno, node_to_remove)
    return geno
end

function indexof(a::Array{Float32}, f::Float32)
    index = findall(x->x==f, a)[1]
    return index
end

function get_neuron_positions(geno::GnarlNetworkGenotype)
    fixed_positions = Float32.(-geno.n_input_nodes:geno.n_output_nodes)
    hidden_positions = Float32.([node.position for node in geno.hidden_nodes])
    neuron_positions = [fixed_positions; hidden_positions]
    return neuron_positions
end

function find_valid_connection_positions(geno::GnarlNetworkGenotype)
    neuron_positions = get_neuron_positions(geno)
    n_neurons = length(neuron_positions)
    # Valid neuron pairs
    valid = trues(n_neurons, n_neurons)
    # Remove existing ones
    for connection in geno.connections
        origin_index = indexof(neuron_positions, connection.origin)
        destination_index = indexof(neuron_positions, connection.destination)
        valid[origin_index, destination_index] = false
    end

    for original_index in 1:n_neurons
        orig_pos = neuron_positions[original_index]
        for destination in 1:n_neurons
            destination_position = neuron_positions[destination]
            # Remove links towards input neurons and bias neuron
            if destination_position <= 0
                valid[original_index, destination] = false
            end
            # Remove links between output neurons (would not support adding a neuron)
            if orig_pos >= 1 
                valid[original_index, destination] = false
            end
        end
    end
    # Filter invalid ones
    connections = findall(valid)
    return connections
end

function add_connection(
    geno::GnarlNetworkGenotype, gene_id::Int, origin::Float32, destination::Float32
)
    new_connection = GnarlNetworkConnectionGene(gene_id, origin, destination, 0.0f0)
    genotype = GnarlNetworkGenotype(
        geno.n_input_nodes, 
        geno.n_output_nodes, 
        geno.hidden_nodes, 
        [geno.connections; new_connection]
    )
    return genotype
end

"Add a connection between 2 random neurons"
function add_connection(rng::AbstractRNG, gene_id_counter::Counter, geno::GnarlNetworkGenotype)
    valid_connections = find_valid_connection_positions(geno)
    if length(valid_connections) == 0
        return geno
    end
    shuffle!(rng, valid_connections) # Pick random
    neuron_positions = get_neuron_positions(geno)
    origin = neuron_positions[valid_connections[1][1]]
    destination = neuron_positions[valid_connections[1][2]]
    if destination <= 0 # Catching error where destination is an input
        throw("Invalid connection")
    end
    gene_id = next!(gene_id_counter)
    geno = add_connection(geno, gene_id, origin, destination)
    return geno
end

function remove_connection(
    geno::GnarlNetworkGenotype, connection::GnarlNetworkConnectionGene
)
    remaining_connections = filter(x -> x != connection, geno.connections)
    genotype = GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, geno.hidden_nodes, remaining_connections
    )
    return genotype
end

function remove_connection(rng::AbstractRNG, ::Counter, geno::GnarlNetworkGenotype)
    if length(geno.connections) == 0
        return geno
    end
    connection_to_remove = rand(rng, geno.connections) # pick a random gene
    geno = remove_connection(geno, connection_to_remove)
    return geno
end


Base.@kwdef struct GnarlNetworkMutator <: Mutator
    n_changes::Int = 1
    probs::Dict{Function, Float64} = Dict(
        add_node => 0.25,
        remove_node => 0.25,
        add_connection => 0.25,
        remove_connection => 0.25
    )
    weight_factor::Float64 = 0.1
end

function mutate(
    mutator::GnarlNetworkMutator, rng::AbstractRNG, gene_id_counter::Counter, geno::Genotype
)
    geno = mutate_weights(rng, geno, mutator.weight_factor)
    functions = collect(keys(mutator.probs))
    function_weights = Weights(collect(values(mutator.probs)))
    mutation_functions = sample(rng, functions, function_weights, mutator.n_changes)
    for mutation_function in mutation_functions
        geno = mutation_function(rng, gene_id_counter, geno)
    end
    return geno
end

end