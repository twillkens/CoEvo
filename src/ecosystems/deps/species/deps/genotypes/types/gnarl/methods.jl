module GnarlMethods

using Random: AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter
using ..GnarlNetworks: GnarlNetworkGenotype, GnarlNetworkConnectionGene, GnarlNetworkNodeGene
import ...Genotypes.Interfaces: create_genotypes

function get_neuron_positions(geno::GnarlNetworkGenotype)
    fixed_positions = Float32.(-geno.n_input_nodes:geno.n_output_nodes)
    hidden_positions = Float32.([node.position for node in geno.hidden_nodes])
    neuron_positions = sort([fixed_positions; hidden_positions])
    return neuron_positions
end
function get_inputs(genotype::GnarlNetworkGenotype)
    Set(Float32(i) for i in -genotype.n_input_nodes:0)
end

function get_outputs(genotype::GnarlNetworkGenotype)
    Set(Float32(i) for i in 1:genotype.n_output_nodes)
end

# ... (other methods remain unchanged)

#function recursive_traversal(
#    current_node::P, 
#    connection_pairs::Set{Tuple{P, P}}, 
#    visited::Set{P}, 
#    from_inputs::Bool
#) where {P <: Real}
#    # Check if the current node has already been visited
#    if current_node in visited
#        return Set{P}()
#    end
#
#    # Mark the current node as visited
#    push!(visited, current_node)
#    
#    # Find next nodes to visit based on the direction
#    next_nodes = from_inputs ? 
#        Set(dest for (orig, dest) in connection_pairs if orig == current_node) : 
#        Set(orig for (orig, dest) in connection_pairs if dest == current_node)
#
#    # Recursively visit the next nodes
#    for node in next_nodes
#        union!(visited, recursive_traversal(node, connection_pairs, visited, from_inputs))
#    end
#    
#    return visited
#end
#
#function get_required_nodes(
#    input_nodes::Set{P},
#    hidden_nodes::Set{P},
#    output_nodes::Set{P},
#    connection_pairs::Set{Tuple{P, P}},
#    from_inputs::Bool
#) where {P <: Real}
#    visited = Set{P}()
#    initial_nodes = from_inputs ? input_nodes : output_nodes
#
#    for node in initial_nodes
#        recursive_traversal(node, connection_pairs, visited, from_inputs)
#    end
#
#    # Filter out only the required hidden nodes
#    return Set(hidden_node for hidden_node in hidden_nodes if hidden_node in visited)
#end
#
## ... (rest of the methods remain unchanged)
#
#end


function get_required_nodes(
    input_nodes::Set{Float32},
    hidden_nodes::Set{Float32},
    output_nodes::Set{Float32},
    connection_pairs::Set{Tuple{Float32, Float32}},
    from_inputs::Bool
)
    required_nodes = from_inputs ? Set(input_nodes) : Set(output_nodes)
    s = from_inputs ? Set(input_nodes) : Set(output_nodes)
    while true
        t = from_inputs ? 
            Set(dest for (orig, dest) in connection_pairs if (orig in s) && !(dest in s)) : 
            Set(orig for (orig, dest) in connection_pairs if (dest in s) && !(orig in s))
        if length(t) == 0
            break
        end
        layer_nodes = Set(x for x in t if !(x in (from_inputs ? output_nodes : input_nodes)))
        if length(layer_nodes) == 0
            break
        end
        required_nodes = union(required_nodes, layer_nodes)
        s = union(s, t)
    end
    Set(hidden_node for hidden_node in hidden_nodes if hidden_node in required_nodes)
end

function get_required_nodes(
    input_nodes::Set{Float32}, 
    hidden_nodes::Set{Float32}, 
    output_nodes::Set{Float32}, 
    connection_pairs::Set{Tuple{Float32, Float32}}
)
    required_input_nodes = get_required_nodes(
        input_nodes, hidden_nodes, output_nodes, connection_pairs, true
    )
    required_output_nodes = get_required_nodes(
        input_nodes, hidden_nodes, output_nodes, connection_pairs, false
    )
    required_nodes = intersect(required_input_nodes, required_output_nodes)
    return required_nodes
end
# the minimize function is used to remove unnecessary hidden_nodes nodes 
function minimize(genotype::GnarlNetworkGenotype)
    input_nodes = get_inputs(genotype)
    hidden_nodes = Set(hidden_node.position for hidden_node in genotype.hidden_nodes)
    output_nodes = get_outputs(genotype)
    connection_pairs = Set(
        (connection.origin, connection.destination) 
        for connection in genotype.connections
    )
    required_hidden_nodes = get_required_nodes(
        input_nodes, hidden_nodes, output_nodes, connection_pairs
    )
    minimal_hidden_nodes = filter(
        x -> x.position in required_hidden_nodes, genotype.hidden_nodes
    )
    minimal_nodes = union(input_nodes, required_hidden_nodes, output_nodes)
    origin_is_minimal = connection -> connection.origin in minimal_nodes
    destination_is_minimal = connection -> connection.destination in minimal_nodes
    minimal_connections = filter(
        connection -> origin_is_minimal(connection) && destination_is_minimal(connection),
        genotype.connections
    )
    GnarlNetworkGenotype(
        genotype.n_input_nodes, 
        genotype.n_output_nodes, 
        minimal_hidden_nodes, 
        minimal_connections
    )
end

end