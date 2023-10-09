module GnarlNetworks

export mutate_weight, GnarlNetworkMutator, mutate_weights, add_node, remove_node
export add_connection, remove_connection, get_neuron_positions, find_valid_connection_positions

using StatsBase: Weights, sample
using ....Species.Genotypes.Abstract: Genotype
using Random: AbstractRNG, shuffle!
using .....Ecosystems.Utilities.Counters: Counter, next!
using  ...Mutators.Abstract: Mutator
using ....Genotypes.GnarlNetworks: GnarlNetworkGenotype, GnarlNetworkConnectionGene, GnarlNetworkNodeGene
using ....Genotypes.GnarlNetworks.GnarlMethods: get_neuron_positions

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

# function mutate_weights(rng::AbstractRNG, geno::GnarlNetworkGenotype, weight_factor::Float64)
#     connections = mutate_weight.(rng, geno.connections, weight_factor)
#     geno = GnarlNetworkGenotype(
#         geno.n_input_nodes, geno.n_output_nodes, geno.hidden_nodes,  connections
#     )
#     return geno
# end

function mutate_weights(rng::AbstractRNG, geno::GnarlNetworkGenotype, weight_factor::Float64)
    # Pick a random index from the connections
    if length(geno.connections) == 0
        return geno
    end
    #connections = copy(geno.connections)
    ##idx = rand(rng, 1:length(connections))
    ## Only mutate the chosen connection's weight
    #connections[idx] = mutate_weight(rng, connections[idx], weight_factor)
    
    connections = [
        mutate_weight(rng, connection, weight_factor) for connection in geno.connections
    ]
    
    # Return a new GnarlNetworkGenotype with the mutated connection
    geno = GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, geno.hidden_nodes, connections
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

function indexof(a::Array{Float32}, f::Float32)
    index = findall(x->x==f, a)[1]
    return index
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

function remove_node(
    geno::GnarlNetworkGenotype, 
    node_to_remove::GnarlNetworkNodeGene,
    connections_to_remove::Vector{GnarlNetworkConnectionGene},
    connections_to_add::Vector{GnarlNetworkConnectionGene}
)
    remaining_nodes = filter(x -> x != node_to_remove, geno.hidden_nodes)
    pruned_connections = filter(x -> x ∉ connections_to_remove, geno.connections)
    new_connections = [pruned_connections; connections_to_add]
    geno = GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, remaining_nodes, new_connections
    )
    return geno
end

function create_connection(
    rng::AbstractRNG,
    gene_id_counter::Counter,
    geno::GnarlNetworkGenotype
)
    valid_connections = find_valid_connection_positions(geno)
    if length(valid_connections) == 0
        return
    end
    shuffle!(rng, valid_connections) # Pick random
    neuron_positions = get_neuron_positions(geno)
    origin = neuron_positions[valid_connections[1][1]]
    destination = neuron_positions[valid_connections[1][2]]
    if destination <= 0 # Catching error where destination is an input
        throw("Invalid connection")
    end
    gene_id = next!(gene_id_counter)
    new_connection = GnarlNetworkConnectionGene(gene_id, origin, destination, 0.0f0)
    return new_connection
end

function remove_node(rng::AbstractRNG, gene_id_counter::Counter, geno::GnarlNetworkGenotype)
    if length(geno.hidden_nodes) == 0
        return geno
    end
    node_to_remove = rand(rng, geno.hidden_nodes)
    connections_to_remove = filter(
        x -> x.origin == node_to_remove.position || x.destination == node_to_remove.position, 
        geno.connections
    )
    pruned_connections = filter(
        x -> x ∉ connections_to_remove,  geno.connections
    )
    pruned_nodes = filter(x -> x != node_to_remove, geno.hidden_nodes)
    pruned_genotype = GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, pruned_nodes, pruned_connections
    )
    connections_to_add = GnarlNetworkConnectionGene[]
    for i in 1:length(connections_to_remove)
        result = create_connection(rng, gene_id_counter, pruned_genotype)
        if result !== nothing
            push!(connections_to_add, result)
            
        end
    end
    geno = remove_node(geno, node_to_remove, connections_to_remove, connections_to_add)
    return geno
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
    mutator::GnarlNetworkMutator, 
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    geno::GnarlNetworkGenotype
)
    geno_before = geno
    geno = mutate_weights(rng, geno, mutator.weight_factor)
    functions = collect(keys(mutator.probs))
    function_weights = Weights(collect(values(mutator.probs)))
    mutation_functions = sample(rng, functions, function_weights, mutator.n_changes)
    guilty = nothing
    for mutation_function in mutation_functions
        geno = mutation_function(rng, gene_id_counter, geno)
        guilty = mutation_function
    end
    neuron_positions = get_neuron_positions(geno)
    origin_nodes = [gene.origin for gene in geno.connections]
    destination_nodes = [gene.destination for gene in geno.connections]
    for node in union(origin_nodes, destination_nodes) 
        if node ∉ neuron_positions
            throw(ErrorException("Invalid mutation: $guilty, node removed but not from links"))
        end
        node_gene_ids = Set(gene.id for gene in geno.hidden_nodes)
        if length(node_gene_ids) != length(geno.hidden_nodes)
            throw(ErrorException("Invalid mutation: $guilty, duplicate node ids"))
        end

        connection_gene_ids = Set(gene.id for gene in geno.connections)
        if length(connection_gene_ids) != length(geno.connections)
            throw(ErrorException("Invalid mutation: $guilty, duplicate connection ids"))
        end
    end
    return geno
end

end
    # println("-------------REMOVE NODE----------")
    # println("geno: $geno")
    # println("node_to_remove: $node_to_remove")
    # println("connections_to_remove: $connections_to_remove")
    # println("pruned_connections: $pruned_connections")
    # println("pruned_nodes: $pruned_nodes")
    # println("pruned_genotype: $pruned_genotype")
    # println("connections_to_add: $connections_to_add")
    # println("remaining_nodes: $remaining_nodes")
    # println("pruned_connections: $pruned_connections")
    # println("new_connections: $new_connections")
    # println("new geno: $geno")

    # println("------------MUTATE----------")
    # println("geno_before: $geno_before")
    # println("neuron_positions: $neuron_positions")
    # println("origin_nodes: $origin_nodes")
    # println("destination_nodes: $destination_nodes")
    # println("geno: $geno")