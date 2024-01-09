
using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.FunctionGraphs
using CoEvo.Mutators.FunctionGraphs
using CoEvo.Mutators.FunctionGraphs: add_function as fg_add_function, remove_function as fg_remove_function
using CoEvo.Phenotypes.FunctionGraphs.Linearized
using CoEvo.Phenotypes.FunctionGraphs.Basic
using ProgressBars

test_genotype = FunctionGraphGenotype(
    input_node_ids = [1, 2],
    bias_node_ids = [3],
    hidden_node_ids = [4, 5, 6],
    output_node_ids = [7],
    nodes = Dict(
        1 => FunctionGraphNode(1, :INPUT, []),
        2 => FunctionGraphNode(2, :INPUT, []),
        3 => FunctionGraphNode(3, :BIAS, []),
        4 => FunctionGraphNode(4, :ADD, [FunctionGraphEdge(1, 1.0, false), FunctionGraphEdge(2, 1.0, false)]),
        5 => FunctionGraphNode(5, :SUBTRACT, [FunctionGraphEdge(3, 1.0, false), FunctionGraphEdge(4, 1.0, false)]),
        6 => FunctionGraphNode(6, :MULTIPLY, [FunctionGraphEdge(2, 1.0, false), FunctionGraphEdge(3, 1.0, false)]),  # Not connected to output
        7 => FunctionGraphNode(7, :OUTPUT, [FunctionGraphEdge(5, 1.0, false)])
    ),
    n_nodes_per_output = 1
)
@testset "minimize function tests" begin
    # Define a small genotype for testing.

    # Minimize the genotype
    minimized_genotype = minimize(test_genotype)
    
        
    # Test 1: Ensure that all nodes in the minimized genotype are connected to output
    @test all(id -> id in minimized_genotype.input_node_ids ||
                   id in minimized_genotype.bias_node_ids ||
                   id in minimized_genotype.hidden_node_ids ||
                   id in minimized_genotype.output_node_ids,
              keys(minimized_genotype.nodes)
          )

    # Test 2: The not connected node (id: 6) should be removed after minimization
    @test !haskey(minimized_genotype.nodes, 6)

    # Test 3: Validate the output node(s) should remain the same after minimization
    @test minimized_genotype.output_node_ids == test_genotype.output_node_ids
    
    # Test 4: Ensure nodes in input, bias, hidden, and output node id vectors really exist in the minimized nodes
    @test all(id -> haskey(minimized_genotype.nodes, id),
              vcat(minimized_genotype.input_node_ids, minimized_genotype.bias_node_ids,
                   minimized_genotype.hidden_node_ids, minimized_genotype.output_node_ids)
          )

    # Test 5: Check if input and bias nodes remain unchanged
    @test minimized_genotype.input_node_ids == test_genotype.input_node_ids
    @test minimized_genotype.bias_node_ids == test_genotype.bias_node_ids
    
    # Test 6: Validate that input, bias, and output nodes in minimized genotype are the same as in the original genotype
    @test all(id -> minimized_genotype.nodes[id] == test_genotype.nodes[id],
              vcat(minimized_genotype.input_node_ids, minimized_genotype.bias_node_ids, minimized_genotype.output_node_ids)
          )
    
end

function extract_bloat(genotype::FunctionGraphGenotype)
    # A Set to store IDs of essential and non-essential nodes.
    essential_nodes_ids = Set{Int}()
    non_essential_nodes_ids = Set{Int}()

    # A function to recursively find essential nodes by traversing input connections.
    function find_essential_nodes(node_id::Int)
        # Avoid repeated work if the node is already identified as essential.
        if node_id in essential_nodes_ids
            return
        end
        
        # Add the current node to essential nodes.
        push!(essential_nodes_ids, node_id)
        
        # Recursively call for all input connections of the current node.
        for conn in genotype.nodes[node_id].input_connections
            find_essential_nodes(conn.input_node_id)
        end
    end

    # Initialize the search for essential nodes from each output node.
    for output_node_id in genotype.output_node_ids
        find_essential_nodes(output_node_id)
    end

    # Ensuring input, bias, and output nodes are always essential.
    union!(essential_nodes_ids, genotype.input_node_ids, genotype.bias_node_ids, genotype.output_node_ids)

    # All nodes not marked as essential are considered non-essential.
    non_essential_nodes_ids = setdiff(Set(keys(genotype.nodes)), essential_nodes_ids)

    # Construct the genotype with only non-essential nodes.
    bloat_nodes = Dict(id => node for (id, node) in genotype.nodes if id in non_essential_nodes_ids)

    # Return a new FunctionGraphGenotype with only non-essential nodes.
    bloated_genotype = FunctionGraphGenotype(
        input_node_ids = [],  # No inputs as they are essential
        bias_node_ids = [],   # No bias nodes as they are essential
        hidden_node_ids = filter(id -> id in non_essential_nodes_ids, genotype.hidden_node_ids), 
        output_node_ids = [], # No outputs as they are essential
        nodes = bloat_nodes,
        n_nodes_per_output = genotype.n_nodes_per_output
    )
    return bloated_genotype
end

# Function to check if a node is connected to any output node
function is_node_connected_to_output(node_id::Int, genotype::FunctionGraphGenotype, checked_nodes::Set{Int} = Set{Int}())
    # If the node is an output node, return true.
    if node_id in genotype.output_node_ids
        return true
    end

    # Avoid infinite loops in case of recurrent connections.
    if node_id in checked_nodes
        return false
    end

    push!(checked_nodes, node_id)

    # Check if any of the input connections leads to an output node.
    for conn in genotype.nodes[node_id].input_connections
        if is_node_connected_to_output(conn.input_node_id, genotype, checked_nodes)
            return true
        end
    end

    # If none of the input connections lead to an output node, return false.
    return false
end



@testset "extract_bloat function tests" begin
    # Define the same small genotype used in minimize tests.

    # Extract bloat from the genotype
    bloated_genotype = extract_bloat(test_genotype)

    # Test 1: Ensure that all nodes in the bloated genotype are not connected to output
    @test all(id -> !(id in bloated_genotype.input_node_ids) &&
                   !(id in bloated_genotype.bias_node_ids) &&
                   id in bloated_genotype.hidden_node_ids &&
                   !(id in bloated_genotype.output_node_ids),
              keys(bloated_genotype.nodes)
          )

    # Test 2: The node that is not connected to output (id: 6) should be present after extraction
    @test haskey(bloated_genotype.nodes, 6)

    # Test 3: Validate the output, input, and bias node IDs should be empty as they are essential
    @test isempty(bloated_genotype.output_node_ids)
    @test isempty(bloated_genotype.input_node_ids)
    @test isempty(bloated_genotype.bias_node_ids)

    # Test 4: Ensure hidden nodes in bloated_genotype are only those not connected to output in original genotype
    @test all(id -> id in test_genotype.hidden_node_ids &&
                   !(is_node_connected_to_output(id, test_genotype)), # Assuming a function that checks node connection to output
              bloated_genotype.hidden_node_ids
          )

    # Test 5: Validate that there are no input, bias, or output nodes in the bloated genotype
    @test isempty(vcat(bloated_genotype.input_node_ids, bloated_genotype.bias_node_ids, bloated_genotype.output_node_ids))
    
    # Test 6: Check if the non-essential nodes in bloated_genotype are the same as in the original genotype
    @test all(id -> bloated_genotype.nodes[id] == test_genotype.nodes[id],
              bloated_genotype.hidden_node_ids
          )
    
end

function get_depth_dictionary(genotype::FunctionGraphGenotype)
    # find the "root nodes" of the genotype graph, which will comprise the input nodes
    # the bias nodes, and nodes that are disconnected from these but are still pointed to by
    # some other node.
    # for each node in the genotype, find the depth, which is the minimum distance 
    # to a root node when traversing through the input connections.
    # return a dictionary mapping node ids to their depths.
end

function remove_nodes_with_highest_depth(
    genotype::FunctionGraphGenotype, 
    depth_dictionary::Dict{Int, Int}, 
    n_remove::Int
)
    # remove the n_remove nodes with the highest depth
end

function get_hidden_nodes(genotype::FunctionGraphGenotype)
    hidden_node_dict = Dict(
        node.id => node for node in genotype.nodes if node.id in genotype.hidden_node_ids
    )
    return hidden_node_dict
end

function merge_hidden_nodes(genotypes::Vector{<:FunctionGraphGenotype})
    first_genotype = popfirst!(genotypes)
    hidden_nodes = get_hidden_nodes(first_genotype)
    for genotype in genotypes
        hidden_nodes = merge(hidden_nodes, get_hidden_nodes(genotype))
    end
    return hidden_nodes
end

function recombine(
    ::HorizontalGeneTransferRecombiner, 
    rng::AbstractRNG,
    donor::FunctionGraphGenotype,
    recipient::FunctionGraphGenotype
)
    active_donor_material = minimize(donor)
    active_recipient_material = minimize(recipient)
    inactive_recipient_material = extract_bloat(recipient)
    depth_dictionary = get_depth_dictionary(inactive_recipient_material)
    n_remove = get_size(recipient) - get_size(active_donor_material)
    remove_nodes_with_highest_depth!(inactive_recipient_material, depth_dictionary, n_remove)
    hidden_nodes = merge_hidden_nodes([
        active_donor_material, active_recipient_material, inactive_recipient_material
    ])
    child = FunctionGraphGenotype(
        input_node_ids = recipient.input_node_ids,
        bias_node_ids = recipient.bias_node_ids,
        hidden_node_ids = [node.id for node in values(hidden_nodes)],
        output_node_ids = active_donor_material.output_node_ids,
        nodes = hidden_nodes,
        n_nodes_per_output = active_donor_material.n_nodes_per_output
    )
end

function recombine(
    ::HorizontalGeneTransferRecombiner,
    ::AbstractRNG, 
    individual_id_counter::Counter, 
    parent_set::Set{<:BasicIndividual}
) 
    children = [
        BasicIndividual(count!(individual_id_counter), parent.genotype, [parent.id]) 
        for parent in parents
    ]
    return children
end
