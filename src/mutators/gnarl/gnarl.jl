module GnarlNetworks

export mutate_weight, GnarlNetworkMutator, mutate_weights, add_node, remove_node
export add_connection, remove_connection, find_valid_connection_positions
export get_next_layer, get_previous_layer
export replace_connection, redirect_or_replace_connection, remove_node_from_genotype
export remove_node_2, redirect_connection

import ...Mutators: mutate

using StatsBase: Weights, sample
using Random: AbstractRNG, shuffle!
using ...Counters: Counter, count!
using ...Genotypes.GnarlNetworks: GnarlNetworkGenotype, GnarlNetworkConnectionGene
using ...Genotypes.GnarlNetworks: GnarlNetworkNodeGene, get_neuron_positions
using ..Mutators: Mutator

function get_next_layer(genotype::GnarlNetworkGenotype, nodes::Vector{Float32})
    next_layer = [
        conn.destination for conn in genotype.connections 
        if conn.origin in nodes && conn.destination != conn.origin
    ]
    return next_layer
end

function get_previous_layer(genotype::GnarlNetworkGenotype, nodes::Vector{Float32})
    previous_layer = [
        conn.origin for conn in genotype.connections 
        if conn.destination in nodes && conn.destination != conn.origin
    ]
    return previous_layer
end

function exists_connection(
    genotype::GnarlNetworkGenotype, origin::Float32, destination::Float32
)
    return any(
        conn -> conn.origin == origin && conn.destination == destination, genotype.connections
    )
end

function is_valid_new_connection(genotype, node_to_remove_position, origin, destination)
    if exists_connection(genotype, origin, destination)
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

#function remove_connection(genotype::GnarlNetworkGenotype, conn::GnarlNetworkConnectionGene)
#    return GnarlNetworkGenotype(
#        genotype.n_input_nodes, genotype.n_output_nodes, genotype.hidden_nodes, 
#        filter(x -> x.id != conn.id, genotype.connections)
#    )
#end

# Core functions
function redirect_connection(
    random_number_generator::AbstractRNG, 
    genotype::GnarlNetworkGenotype, 
    node_to_remove_position::Float32,
    connection::GnarlNetworkConnectionGene
)
    available_destinations = setdiff(get_neuron_positions(genotype), [connection.origin])
    valid_destinations = filter(
        destination -> is_valid_new_connection(
            genotype, node_to_remove_position, connection.origin, destination
        ), 
        available_destinations
    )
    if isempty(valid_destinations)
        return nothing
    end
    new_destination = rand(random_number_generator, valid_destinations)
    return new_destination
end



function replace_connection(
    genotype::GnarlNetworkGenotype, 
    old_conn::GnarlNetworkConnectionGene, 
    new_conn::GnarlNetworkConnectionGene
)
    #println("old_conn: $old_conn")
    #println("new_conn: $new_conn")
    new_connections = deepcopy(genotype.connections)
    new_connections[findfirst(x -> x.id == old_conn.id, new_connections)] = new_conn
    return GnarlNetworkGenotype(genotype.n_input_nodes, genotype.n_output_nodes, genotype.hidden_nodes, new_connections)
end



function fallback_random_connection(
    random_number_generator::AbstractRNG,
    genotype::GnarlNetworkGenotype,
    node_to_remove_position::Float32,
)
    #println("------------FALLBACK RANDOM CONNECTION------------")
    # Get possible origins: only input and hidden nodes (excluding output nodes and node_to_remove_position)
    possible_origins = filter(n -> n < 1.0, get_neuron_positions(genotype))
    available_origins = setdiff(possible_origins, [node_to_remove_position])

    # Get possible destinations: only hidden and output nodes (excluding input nodes and node_to_remove_position)
    possible_destinations = filter(n -> n > 0.0, get_neuron_positions(genotype))
    available_destinations = setdiff(possible_destinations, [node_to_remove_position])

    # Filter to only valid connection pairs
    valid_pairs = [
        (o, d) for o in available_origins for d in available_destinations 
        if is_valid_new_connection(genotype, node_to_remove_position, o, d)
    ]

    if isempty(valid_pairs)
        return nothing, nothing
    end

    return rand(random_number_generator, valid_pairs)
end


function get_valid_next_step(
    genotype::GnarlNetworkGenotype, 
    current_nodes::Vector{Float32}, 
    direction::Symbol
)
    if direction == :incoming
        return get_next_layer(genotype, current_nodes)
    else
        return get_previous_layer(genotype, current_nodes)
    end
end

function attempt_cascade(
    genotype::GnarlNetworkGenotype, 
    node_to_remove_position::Float32, 
    connection::GnarlNetworkConnectionGene, 
    direction::Symbol
)
    current_nodes = direction == :incoming ? [connection.destination] : [connection.origin]
    next_nodes = get_valid_next_step(genotype, current_nodes, direction)
    next_nodes = filter(
        n -> is_valid_new_connection(genotype, node_to_remove_position, connection.origin, n),
        next_nodes
    )
    return isempty(next_nodes) ? nothing : rand(next_nodes)
end

function redirect_or_replace_connection(random_number_generator, genotype, node_to_remove_position, connection, direction)
    if direction == :incoming
        new_destination = attempt_cascade(genotype, node_to_remove_position, connection, direction)
        if new_destination === nothing
            new_destination = redirect_connection(random_number_generator, genotype, node_to_remove_position, connection)
        end
        if new_destination === nothing
            origin, destination = fallback_random_connection(random_number_generator, genotype, node_to_remove_position)
            if origin === nothing || destination === nothing
                return nothing
            end
        else
            origin, destination = connection.origin, new_destination
        end
    else
        new_origin = attempt_cascade(genotype, node_to_remove_position, connection, direction)
        if new_origin === nothing
            new_origin = redirect_connection(random_number_generator, genotype, node_to_remove_position, connection)
        end
        if new_origin === nothing
            origin, destination = fallback_random_connection(random_number_generator, genotype, node_to_remove_position)
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

function remove_node_from_genotype(genotype::GnarlNetworkGenotype, node_to_remove::GnarlNetworkNodeGene)
    return GnarlNetworkGenotype(
        genotype.n_input_nodes, genotype.n_output_nodes, filter(node -> node != node_to_remove, genotype.hidden_nodes), genotype.connections
    )
end

function remove_node_2(random_number_generator::AbstractRNG, genotype::GnarlNetworkGenotype, node_to_remove::GnarlNetworkNodeGene)
    #println("------------REMOVE NODE 2------------")
    #println("node_to_remove: $node_to_remove")
    incoming_connections = filter(conn -> conn.destination == node_to_remove.position && conn.destination != conn.origin, genotype.connections)
    outgoing_connections = filter(conn -> conn.origin == node_to_remove.position && conn.origin != conn.destination, genotype.connections)
    self_connections = filter(conn -> conn.origin == node_to_remove.position && conn.origin == conn.destination, genotype.connections)
    
    updated_geno = deepcopy(genotype)
    if length(self_connections) > 0
        #println("connection.destination == connection.origin")
        updated_geno = remove_connection(updated_geno, self_connections[1])
    end
    for conn in incoming_connections
        new_conn = redirect_or_replace_connection(random_number_generator, updated_geno, node_to_remove.position, conn, :incoming)
        if new_conn === nothing
            #println("new_conn is nothing for incoming")
            updated_geno = remove_connection(updated_geno, conn)
        else
            #println("new_conn is not nothing for incoming")
            updated_geno = replace_connection(updated_geno, conn, new_conn)
        end
    end

    for conn in outgoing_connections
        new_conn = redirect_or_replace_connection(random_number_generator, updated_geno, node_to_remove.position, conn, :outgoing)
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

function remove_node_2(random_number_generator::AbstractRNG, ::Counter, genotype::GnarlNetworkGenotype)
    return length(genotype.hidden_nodes) == 0 ? deepcopy(genotype) : remove_node_2(random_number_generator, genotype, rand(random_number_generator, genotype.hidden_nodes))
end


function redirect_connection(
    random_number_generator::AbstractRNG,
    genotype::GnarlNetworkGenotype,
    connection::GnarlNetworkConnectionGene,
)
    # Fetch all neuron positions except the current connection's origin
    available_destinations = setdiff(get_neuron_positions(genotype), [connection.origin])

    # Exclude destinations which already have a connection from the source node
    available_destinations = filter(
        destination -> is_valid_new_connection(
            genotype, -999f0, connection.origin, destination
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
    new_destination = rand(random_number_generator, available_destinations)

    return GnarlNetworkConnectionGene(
        id = connection.id, 
        origin = connection.origin, 
        destination = new_destination, 
        weight = connection.weight
    )
end


function redirect_connection(
    random_number_generator::AbstractRNG,
    ::Counter,
    genotype::GnarlNetworkGenotype, 
)
    if length(genotype.connections) == 0
        return deepcopy(genotype)
    end
    connection = rand(random_number_generator, genotype.connections)
    # Decide which end to redirect
    new_connection = redirect_connection(random_number_generator, genotype, connection)
    new_genotype = replace_connection(genotype, connection, new_connection)
    return new_genotype
end


"Mutate the weight of genes"
function mutate_weight(
    random_number_generator::AbstractRNG, connection::GnarlNetworkConnectionGene, weight_factor::Float64
)
    connection = GnarlNetworkConnectionGene(
        connection.id, 
        connection.origin, 
        connection.destination, 
        connection.weight + randn(random_number_generator) * weight_factor, 
    )
    return connection
end

# function mutate_weights(random_number_generator::AbstractRNG, genotype::GnarlNetworkGenotype, weight_factor::Float64)
#     connections = mutate_weight.(random_number_generator, genotype.connections, weight_factor)
#     genotype = GnarlNetworkGenotype(
#         genotype.n_input_nodes, genotype.n_output_nodes, genotype.hidden_nodes,  connections
#     )
#     return genotype
# end

function mutate_weights(random_number_generator::AbstractRNG, genotype::GnarlNetworkGenotype, weight_factor::Float64)
    # Pick a random index from the connections
    if length(genotype.connections) == 0
        return genotype
    end
    
    connections = [
        mutate_weight(random_number_generator, connection, weight_factor) for connection in genotype.connections
    ]
    
    # Return a new GnarlNetworkGenotype with the mutated connection
    genotype = GnarlNetworkGenotype(
        genotype.n_input_nodes, genotype.n_output_nodes, genotype.hidden_nodes, connections
    )
    return genotype
end

function add_node(genotype::GnarlNetworkGenotype, gene_id::Int, position::Float32)
    node = GnarlNetworkNodeGene(gene_id, position)
    hidden_nodes = [genotype.hidden_nodes; node]
    genotype = GnarlNetworkGenotype(
        genotype.n_input_nodes, genotype.n_output_nodes, hidden_nodes, genotype.connections
    )
    return genotype
end

function add_node(random_number_generator::AbstractRNG, gene_id_counter::Counter, genotype::GnarlNetworkGenotype)
    gene_id = count!(gene_id_counter)
    position = Float32(rand(random_number_generator))
    genotype = add_node(genotype, gene_id, position)
    return genotype
end

function indexof(a::Array{Float32}, f::Float32)
    index = findall(x->x==f, a)[1]
    return index
end


function find_valid_connection_positions(genotype::GnarlNetworkGenotype)
    neuron_positions = get_neuron_positions(genotype)
    n_neurons = length(neuron_positions)
    # Valid neuron pairs
    valid = trues(n_neurons, n_neurons)
    # Remove existing ones
    for connection in genotype.connections
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
    genotype::GnarlNetworkGenotype, 
    node_to_remove::GnarlNetworkNodeGene,
    connections_to_remove::Vector{GnarlNetworkConnectionGene},
    connections_to_add::Vector{GnarlNetworkConnectionGene}
)
    remaining_nodes = filter(x -> x != node_to_remove, genotype.hidden_nodes)
    pruned_connections = filter(x -> x ∉ connections_to_remove, genotype.connections)
    new_connections = [pruned_connections; connections_to_add]
    genotype = GnarlNetworkGenotype(
        genotype.n_input_nodes, genotype.n_output_nodes, remaining_nodes, new_connections
    )
    return genotype
end

function create_connection(
    random_number_generator::AbstractRNG,
    gene_id_counter::Counter,
    genotype::GnarlNetworkGenotype
)
    valid_connections = find_valid_connection_positions(genotype)
    if length(valid_connections) == 0
        return
    end
    shuffle!(random_number_generator, valid_connections) # Pick random
    neuron_positions = get_neuron_positions(genotype)
    origin = neuron_positions[valid_connections[1][1]]
    destination = neuron_positions[valid_connections[1][2]]
    if destination <= 0 # Catching error where destination is an input
        throw("Invalid connection")
    end
    gene_id = count!(gene_id_counter)
    new_connection = GnarlNetworkConnectionGene(gene_id, origin, destination, 0.0f0)
    return new_connection
end

function remove_node(random_number_generator::AbstractRNG, gene_id_counter::Counter, genotype::GnarlNetworkGenotype)
    if length(genotype.hidden_nodes) == 0
        return genotype
    end
    node_to_remove = rand(random_number_generator, genotype.hidden_nodes)
    connections_to_remove = filter(
        x -> x.origin == node_to_remove.position || x.destination == node_to_remove.position, 
        genotype.connections
    )
    pruned_connections = filter(
        x -> x ∉ connections_to_remove,  genotype.connections
    )
    pruned_nodes = filter(x -> x != node_to_remove, genotype.hidden_nodes)
    pruned_genotype = GnarlNetworkGenotype(
        genotype.n_input_nodes, genotype.n_output_nodes, pruned_nodes, pruned_connections
    )
    connections_to_add = GnarlNetworkConnectionGene[]
    for i in 1:length(connections_to_remove)
        result = create_connection(random_number_generator, gene_id_counter, pruned_genotype)
        if result !== nothing
            push!(connections_to_add, result)
            
        end
    end
    genotype = remove_node(genotype, node_to_remove, connections_to_remove, connections_to_add)
    return genotype
end

function add_connection(
    genotype::GnarlNetworkGenotype, gene_id::Int, origin::Float32, destination::Float32
)
    new_connection = GnarlNetworkConnectionGene(gene_id, origin, destination, 0.0f0)
    genotype = GnarlNetworkGenotype(
        genotype.n_input_nodes, 
        genotype.n_output_nodes, 
        genotype.hidden_nodes, 
        [genotype.connections; new_connection]
    )
    return genotype
end

"Add a connection between 2 random neurons"
function add_connection(random_number_generator::AbstractRNG, gene_id_counter::Counter, genotype::GnarlNetworkGenotype)
    valid_connections = find_valid_connection_positions(genotype)
    if length(valid_connections) == 0
        return genotype
    end
    shuffle!(random_number_generator, valid_connections) # Pick random
    neuron_positions = get_neuron_positions(genotype)
    origin = neuron_positions[valid_connections[1][1]]
    destination = neuron_positions[valid_connections[1][2]]
    if destination <= 0 # Catching error where destination is an input
        throw("Invalid connection")
    end
    gene_id = count!(gene_id_counter)
    genotype = add_connection(genotype, gene_id, origin, destination)
    return genotype
end

function remove_connection(
    genotype::GnarlNetworkGenotype, connection::GnarlNetworkConnectionGene
)
    remaining_connections = filter(x -> x != connection, genotype.connections)
    genotype = GnarlNetworkGenotype(
        genotype.n_input_nodes, genotype.n_output_nodes, genotype.hidden_nodes, remaining_connections
    )
    return genotype
end

function remove_connection(random_number_generator::AbstractRNG, ::Counter, genotype::GnarlNetworkGenotype)
    if length(genotype.connections) == 0
        return genotype
    end
    connection_to_remove = rand(random_number_generator, genotype.connections) # pick a random gene
    genotype = remove_connection(genotype, connection_to_remove)
    return genotype
end

function identity_mutation(
    random_number_generator::AbstractRNG, 
    gene_id_counter::Counter, 
    genotype::GnarlNetworkGenotype
)
    return genotype
end

Base.@kwdef struct GnarlNetworkMutator <: Mutator
    n_changes::Int = 1
    probs::Dict{Symbol, Float64} = Dict(
        :add_node => 1 / 8,
        :remove_node => 1 / 8,
        :add_connection => 1 / 8,
        :remove_connection => 1 / 8,
        :identity_mutation => 1 / 2
    )
    symbol_to_function_dict = Dict(
        :add_node => add_node,
        :remove_node => remove_node,
        :remove_node_2 => remove_node_2,
        :add_connection => add_connection,
        :remove_connection => remove_connection,
        :redirect_connection => redirect_connection,
        :identity_mutation => identity_mutation
    )
    weight_factor::Float64 = 0.1
end


function mutate(
    mutator::GnarlNetworkMutator, 
    random_number_generator::AbstractRNG, 
    gene_id_counter::Counter, 
    genotype::GnarlNetworkGenotype
)
    geno_before = genotype
    genotype = mutate_weights(random_number_generator, genotype, mutator.weight_factor)
    functions = collect(keys(mutator.probs))
    function_weights = Weights(collect(values(mutator.probs)))
    mutation_functions = sample(random_number_generator, functions, function_weights, mutator.n_changes)
    guilty = nothing
    for mutation_function in mutation_functions
        genotype = mutator.symbol_to_function_dict[mutation_function](random_number_generator, gene_id_counter, genotype)
        guilty = mutation_function
    end
    neuron_positions = get_neuron_positions(genotype)
    origin_nodes = [gene.origin for gene in genotype.connections]
    destination_nodes = [gene.destination for gene in genotype.connections]
    for node in union(origin_nodes, destination_nodes) 
        if node ∉ neuron_positions
            println("genotype before: $geno_before")
            println("genotype after: $genotype")
            throw(ErrorException("Invalid mutation: $guilty, node removed but not from links"))
        end
        node_gene_ids = Set(gene.id for gene in genotype.hidden_nodes)
        if length(node_gene_ids) != length(genotype.hidden_nodes)
            println("genotype before: $geno_before")
            println("genotype after: $genotype")
            throw(ErrorException("Invalid mutation: $guilty, duplicate node ids"))
        end

        connection_gene_ids = Set(gene.id for gene in genotype.connections)
        if length(connection_gene_ids) != length(genotype.connections)
            println("genotype before: $geno_before")
            println("genotype after: $genotype")
            throw(ErrorException("Invalid mutation: $guilty, duplicate connection ids"))
        end
    end
    return genotype
end

end