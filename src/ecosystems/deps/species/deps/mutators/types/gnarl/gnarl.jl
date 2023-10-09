module GnarlNetworks

export mutate_weight, GnarlNetworkMutator, mutate_weights, add_node, remove_node
export add_connection, remove_connection, get_neuron_positions, find_valid_connection_positions
export find_available_nodes, get_next_layer, get_previous_layer, create_unique_random_connection
export replace_connection, redirect_or_replace_connection, remove_node_from_genotype
export remove_node_2, redirect_connection

using StatsBase: Weights, sample
using ....Species.Genotypes.Abstract: Genotype
using Random: AbstractRNG, shuffle!
using .....Ecosystems.Utilities.Counters: Counter, next!
using  ...Mutators.Abstract: Mutator
using ....Genotypes.GnarlNetworks: GnarlNetworkGenotype, GnarlNetworkConnectionGene, GnarlNetworkNodeGene
using ....Genotypes.GnarlNetworks.GnarlMethods: get_neuron_positions

import ...Mutators.Interfaces: mutate



# Utility functions
function get_next_layer(geno::GnarlNetworkGenotype, nodes::Vector{Float32})
    return [conn.destination for conn in geno.connections if conn.origin in nodes && conn.destination != conn.origin]
end

function get_previous_layer(geno::GnarlNetworkGenotype, nodes::Vector{Float32})
    return [conn.origin for conn in geno.connections if conn.destination in nodes && conn.destination != conn.origin]
end

function exists_connection(geno::GnarlNetworkGenotype, origin::Float32, destination::Float32)
    return any(conn -> conn.origin == origin && conn.destination == destination, geno.connections)
end

function is_valid_new_connection(geno, node_to_remove_position, origin, destination)
    if exists_connection(geno, origin, destination)
        return false
    end

    if origin == node_to_remove_position || 
            destination == node_to_remove_position || 
            destination <= 0.0 || 
            origin >= 1.0
        return false
    end
    return true
end

function remove_connection(geno::GnarlNetworkGenotype, conn::GnarlNetworkConnectionGene)
    return GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, geno.hidden_nodes, 
        filter(x -> x.id != conn.id, geno.connections)
    )
end

# Core functions
function redirect_connection(rng, geno, node_to_remove_position, connection)
    available_destinations = setdiff(get_neuron_positions(geno), [connection.origin])
    valid_destinations = filter(dest -> is_valid_new_connection(geno, node_to_remove_position, connection.origin, dest), available_destinations)
    
    if isempty(valid_destinations)
        return nothing
    end

    return rand(rng, valid_destinations)
end



function replace_connection(
    geno::GnarlNetworkGenotype, 
    old_conn::GnarlNetworkConnectionGene, 
    new_conn::GnarlNetworkConnectionGene
)
    #println("old_conn: $old_conn")
    #println("new_conn: $new_conn")
    new_connections = deepcopy(geno.connections)
    new_connections[findfirst(x -> x.id == old_conn.id, new_connections)] = new_conn
    return GnarlNetworkGenotype(geno.n_input_nodes, geno.n_output_nodes, geno.hidden_nodes, new_connections)
end



function fallback_random_connection(
    rng::AbstractRNG,
    geno::GnarlNetworkGenotype,
    node_to_remove_position::Float32,
)
    #println("------------FALLBACK RANDOM CONNECTION------------")
    # Get possible origins: only input and hidden nodes (excluding output nodes and node_to_remove_position)
    possible_origins = filter(n -> n < 1.0, get_neuron_positions(geno))
    available_origins = setdiff(possible_origins, [node_to_remove_position])

    # Get possible destinations: only hidden and output nodes (excluding input nodes and node_to_remove_position)
    possible_destinations = filter(n -> n > 0.0, get_neuron_positions(geno))
    available_destinations = setdiff(possible_destinations, [node_to_remove_position])

    # Filter to only valid connection pairs
    valid_pairs = [
        (o, d) for o in available_origins for d in available_destinations 
        if is_valid_new_connection(geno, node_to_remove_position, o, d)
    ]

    if isempty(valid_pairs)
        return nothing, nothing
    end

    return rand(rng, valid_pairs)
end


function get_valid_next_step(
    geno::GnarlNetworkGenotype, 
    current_nodes::Vector{Float32}, 
    direction::Symbol
)
    if direction == :incoming
        return get_next_layer(geno, current_nodes)
    else
        return get_previous_layer(geno, current_nodes)
    end
end

function attempt_cascade(geno, node_to_remove_position, connection, direction)
    current_nodes = direction == :incoming ? [connection.destination] : [connection.origin]
    next_nodes = get_valid_next_step(geno, current_nodes, direction)
    next_nodes = filter(
        n -> is_valid_new_connection(geno, node_to_remove_position, connection.origin, n),
        next_nodes
    )
    return isempty(next_nodes) ? nothing : rand(next_nodes)
end

function redirect_or_replace_connection(rng, geno, node_to_remove_position, connection, direction)
    if direction == :incoming
        new_destination = attempt_cascade(geno, node_to_remove_position, connection, direction)
        if new_destination === nothing
            new_destination = redirect_connection(rng, geno, node_to_remove_position, connection)
        end
        if new_destination === nothing
            origin, destination = fallback_random_connection(rng, geno, node_to_remove_position)
            if origin === nothing || destination === nothing
                return nothing
            end
        else
            origin, destination = connection.origin, new_destination
        end
    else
        new_origin = attempt_cascade(geno, node_to_remove_position, connection, direction)
        if new_origin === nothing
            new_origin = redirect_connection(rng, geno, node_to_remove_position, connection)
        end
        if new_origin === nothing
            origin, destination = fallback_random_connection(rng, geno, node_to_remove_position)
            if origin === nothing || destination === nothing
                return nothing
            end
        else
            origin, destination = new_origin, connection.destination
        end
    end
    return GnarlNetworkConnectionGene(connection.id, origin, destination, connection.weight)
end

# Remaining functions stay mostly unchanged, but you'd need to handle the case where redirect_or_replace_connection returns nothing, in which case you'd remove the connection.

function remove_node_from_genotype(geno::GnarlNetworkGenotype, node_to_remove::GnarlNetworkNodeGene)
    return GnarlNetworkGenotype(
        geno.n_input_nodes, geno.n_output_nodes, filter(node -> node != node_to_remove, geno.hidden_nodes), geno.connections
    )
end

function remove_node_2(rng::AbstractRNG, geno::GnarlNetworkGenotype, node_to_remove::GnarlNetworkNodeGene)
    #println("------------REMOVE NODE 2------------")
    #println("node_to_remove: $node_to_remove")
    incoming_connections = filter(conn -> conn.destination == node_to_remove.position && conn.destination != conn.origin, geno.connections)
    outgoing_connections = filter(conn -> conn.origin == node_to_remove.position && conn.origin != conn.destination, geno.connections)
    self_connections = filter(conn -> conn.origin == node_to_remove.position && conn.origin == conn.destination, geno.connections)
    
    updated_geno = deepcopy(geno)
    if length(self_connections) > 0
        #println("connection.destination == connection.origin")
        updated_geno = remove_connection(updated_geno, self_connections[1])
    end
    for conn in incoming_connections
        new_conn = redirect_or_replace_connection(rng, updated_geno, node_to_remove.position, conn, :incoming)
        if new_conn === nothing
            #println("new_conn is nothing for incoming")
            updated_geno = remove_connection(updated_geno, conn)
        else
            #println("new_conn is not nothing for incoming")
            updated_geno = replace_connection(updated_geno, conn, new_conn)
        end
    end

    for conn in outgoing_connections
        new_conn = redirect_or_replace_connection(rng, updated_geno, node_to_remove.position, conn, :outgoing)
        if new_conn === nothing
            #println("new_conn is nothing for outgoing")
            updated_geno = remove_connection(updated_geno, conn)
        else
            #println("new_conn is not nothing for outgoing")
            updated_geno = replace_connection(updated_geno, conn, new_conn)
        end
    end

    return remove_node_from_genotype(updated_geno, node_to_remove)
end

function remove_node_2(rng::AbstractRNG, ::Counter, geno::GnarlNetworkGenotype)
    return length(geno.hidden_nodes) == 0 ? deepcopy(geno) : remove_node_2(rng, geno, rand(rng, geno.hidden_nodes))
end


function redirect_connection(
    rng::AbstractRNG,
    geno::GnarlNetworkGenotype,
    connection::GnarlNetworkConnectionGene,
)
    # Fetch all neuron positions except the current connection's origin
    available_destinations = setdiff(get_neuron_positions(geno), [connection.origin])

    # Exclude destinations which already have a connection from the source node
    available_destinations = filter(
        destination -> is_valid_new_connection(
            geno, -999f0, connection.origin, destination
        ),
        available_destinations
    )

    available_destinations = filter(
        destination ->  destination > 0.0, available_destinations
    )

    # Safety check: If no available destinations, throw an exception
    if isempty(available_destinations)
        return deepcopy(connection)
    end

    # Choose a random available destination
    new_destination = rand(rng, available_destinations)

    return GnarlNetworkConnectionGene(
        id = connection.id, 
        origin = connection.origin, 
        destination = new_destination, 
        weight = connection.weight
    )
end


function redirect_connection(
    rng::AbstractRNG,
    ::Counter,
    geno::GnarlNetworkGenotype, 
)
    if length(geno.connections) == 0
        return deepcopy(geno)
    end
    connection = rand(rng, geno.connections)
    # Decide which end to redirect
    new_connection = redirect_connection(rng, geno, connection)
    new_genotype = replace_connection(geno, connection, new_connection)
    return new_genotype
end


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
        add_node => 1 / 5,
        remove_node_2 => 1 / 5,
        add_connection => 1 / 5,
        remove_connection => 1 / 5,
        redirect_connection => 1 / 5
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
        #println("------------------------------------MUTATAEEEE-------------------------------")
        #println("mutation_function: $mutation_function")
        #println("geno: $geno")
        geno = mutation_function(rng, gene_id_counter, geno)
        guilty = mutation_function
    end
    neuron_positions = get_neuron_positions(geno)
    origin_nodes = [gene.origin for gene in geno.connections]
    destination_nodes = [gene.destination for gene in geno.connections]
    for node in union(origin_nodes, destination_nodes) 
        if node ∉ neuron_positions
            println("geno before: $geno_before")
            println("geno after: $geno")
            throw(ErrorException("Invalid mutation: $guilty, node removed but not from links"))
        end
        node_gene_ids = Set(gene.id for gene in geno.hidden_nodes)
        if length(node_gene_ids) != length(geno.hidden_nodes)
            println("geno before: $geno_before")
            println("geno after: $geno")
            throw(ErrorException("Invalid mutation: $guilty, duplicate node ids"))
        end

        connection_gene_ids = Set(gene.id for gene in geno.connections)
        if length(connection_gene_ids) != length(geno.connections)
            println("geno before: $geno_before")
            println("geno after: $geno")
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