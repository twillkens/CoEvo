using Test
#include("../../src/CoEvo.jl")
#using .CoEvo
using .Mutators.Types.GnarlNetworks: remove_node_2, redirect_or_replace_connection
using .Mutators.Types.GnarlNetworks: get_next_layer, get_previous_layer
using .Mutators.Types.GnarlNetworks: replace_connection
using .Mutators.Types.GnarlNetworks: redirect_connection, get_neuron_positions

using StableRNGs: StableRNG

# Sample data setup
input_node = GnarlNetworkNodeGene(1, -1.0f0)
hidden_node1 = GnarlNetworkNodeGene(2, 0.5f0)
hidden_node2 = GnarlNetworkNodeGene(3, 0.7f0)
output_node = GnarlNetworkNodeGene(4, 1.0f0)

conn1 = GnarlNetworkConnectionGene(1, input_node.position, hidden_node1.position, 0.5f0)
conn2 = GnarlNetworkConnectionGene(2, hidden_node1.position, output_node.position, 0.5f0)

genotype = GnarlNetworkGenotype(1, 1, [hidden_node1, hidden_node2], [conn1, conn2])
rng = StableRNG(42)
counter = Counter()

# Tests for auxiliary functions
@testset "Auxiliary Functions" begin
    # @test find_available_nodes(genotype, [input_node.position]) == [output_node.position]
    @test get_next_layer(genotype, [input_node.position]) == [hidden_node1.position]
    @test get_previous_layer(genotype, [output_node.position]) == [hidden_node1.position]
end

# Test for connection redirection/replacement logic
@testset "Connection Redirection" begin
    # With the given sample data, redirecting the connection from input_node should 
    # redirect it to either hidden_node2 or directly to output_node.
    redirected_conn = redirect_or_replace_connection(rng, genotype, 0.5f0, conn1, :incoming)
    @test redirected_conn.origin == conn1.origin
    @test redirected_conn.destination in [hidden_node2.position, output_node.position]
end

# Test for removing nodes
@testset "Node Removal" begin
    mutated_genotype = remove_node_2(rng, deepcopy(genotype), hidden_node1)
    # Ensure hidden_node1 is removed
    @test !in(hidden_node1, mutated_genotype.hidden_nodes)
    # Ensure all connections related to hidden_node1 are redirected or replaced
    related_conns = filter(c -> c.origin == hidden_node1.position || c.destination == hidden_node1.position, mutated_genotype.connections)
    @test isempty(related_conns)
end

# You can extend these tests with more complex genotypes, and also include edge cases you might anticipate.

# @testset "Available Nodes with Multiple Input Nodes" begin
#     # Assuming nodes and genotype are initialized as before
#     @test find_available_nodes(genotype, [input_node.position, hidden_node2.position]) == [output_node.position]
# end

@testset "Redirection Cascading" begin
    # Adding a new connection to simulate cascade scenario
    conn3 = GnarlNetworkConnectionGene(3, hidden_node2.position, output_node.position, 0.5f0)
    genotype_with_cascade = GnarlNetworkGenotype(genotype.n_input_nodes, genotype.n_output_nodes, genotype.hidden_nodes, [conn1, conn2, conn3])
    
    # This should cause the redirect_or_replace_connection function to cascade through hidden_node2 to find an available node
    redirected_conn = redirect_or_replace_connection(rng, genotype_with_cascade, 0.5f0, conn1, :incoming)
    @test redirected_conn.destination == output_node.position
end

@testset "Replace Connection Functionality" begin
    old_genotype = deepcopy(genotype)
    new_conn = GnarlNetworkConnectionGene(4, input_node.position, output_node.position, 0.5f0)
    new_genotype = replace_connection(old_genotype, conn1, new_conn)
    
    # Check if the old connection is replaced and the new connection exists
    @test !in(conn1, new_genotype.connections)
    @test in(new_conn, new_genotype.connections)
end

@testset "Redirection Towards Input Nodes" begin
    # Redirecting an outgoing connection from an input node should prioritize non-input nodes
    redirected_conn = redirect_or_replace_connection(rng, genotype, 0.7f0, conn2, :outgoing)
    @test redirected_conn.origin != output_node.position
end

@testset "Node Removal Impact on Other Nodes" begin
    mutated_genotype = remove_node_2(rng, deepcopy(genotype), hidden_node1)
    # Check if only the targeted node is removed and others remain unaffected
    @test !in(hidden_node1, mutated_genotype.hidden_nodes)
    @test in(hidden_node2, mutated_genotype.hidden_nodes)
end

input_nodes = [
    GnarlNetworkNodeGene(id=1, position=-3.0),
    GnarlNetworkNodeGene(id=2, position=-2.0),
    GnarlNetworkNodeGene(id=3, position=-1.0)
]

bias_node = GnarlNetworkNodeGene(id=4, position=0.0)

hidden_nodes = [
    GnarlNetworkNodeGene(id=5, position=0.2),
    GnarlNetworkNodeGene(id=6, position=0.5),
    GnarlNetworkNodeGene(id=7, position=0.8)
]

output_nodes = [
    GnarlNetworkNodeGene(id=8, position=1.0),
    GnarlNetworkNodeGene(id=9, position=2.0),
    GnarlNetworkNodeGene(id=10, position=3.0)
]

connections = [
    GnarlNetworkConnectionGene(id=1, origin=-3.0, destination=0.2, weight=0.5f0),
    GnarlNetworkConnectionGene(id=2, origin=-2.0, destination=0.5, weight=0.6f0),
    GnarlNetworkConnectionGene(id=3, origin=-1.0, destination=0.8, weight=0.7f0),
    GnarlNetworkConnectionGene(id=4, origin=0.0, destination=0.2, weight=1.0f0),
    GnarlNetworkConnectionGene(id=5, origin=0.2, destination=0.5, weight=0.9f0),
    GnarlNetworkConnectionGene(id=6, origin=0.5, destination=0.8, weight=0.8f0),
    GnarlNetworkConnectionGene(id=7, origin=0.8, destination=1.0, weight=0.6f0),
    GnarlNetworkConnectionGene(id=8, origin=0.2, destination=1.0, weight=0.5f0),
    GnarlNetworkConnectionGene(id=9, origin=0.5, destination=2.0, weight=0.6f0),
    GnarlNetworkConnectionGene(id=10, origin=0.8, destination=3.0, weight=0.7f0)
]

genotype = GnarlNetworkGenotype(
    n_input_nodes=length(input_nodes),
    n_output_nodes=length(output_nodes),
    hidden_nodes=hidden_nodes,
    connections=connections
)

@testset "Layer fetching functions" begin
    @test get_next_layer(genotype, Float32[-2.0]) == [0.5]
    @test Set(get_previous_layer(genotype, Float32[0.5])) == Set(Float32[-2.0, 0.2])
end

@testset "replace_connection function" begin
    old_conn = GnarlNetworkConnectionGene(id=5, origin=0.2, destination=0.5, weight=0.9f0)
    new_conn = GnarlNetworkConnectionGene(id=5, origin=0.2, destination=2.0, weight=0.9f0)
    replaced_genotype = replace_connection(genotype, old_conn, new_conn)
    
    @test !in(old_conn, replaced_genotype.connections)
    @test in(new_conn, replaced_genotype.connections)
end

@testset "redirect_or_replace_connection function" begin
    connection = GnarlNetworkConnectionGene(id=2, origin=-2.0, destination=0.5, weight=0.6f0)
    new_conn = redirect_or_replace_connection(rng, genotype, 0.5f0, connection, :incoming)
    @test new_conn.origin == connection.origin
    @test new_conn.destination != connection.destination
end

@testset "Node Removal" begin
    mutated_genotype = remove_node_2(rng, deepcopy(genotype), hidden_nodes[1])
    # Ensure hidden_node1 (position 0.2) is removed
    @test !in(hidden_nodes[1], mutated_genotype.hidden_nodes)
    # Ensure all connections related to hidden_node1 are redirected or replaced
    related_conns = filter(
        c -> c.origin == hidden_nodes[1].position || c.destination == hidden_nodes[1].position, 
        mutated_genotype.connections
    )
    @test isempty(related_conns)
end

@testset "Advanced Test Cases" begin
    # Given the dummy genotype structure we have

    # Test Case 1: Remove node at position 0.2
    mutated_genotype_1 = remove_node_2(rng, deepcopy(genotype), hidden_nodes[1])
    @test !in(hidden_nodes[1], mutated_genotype_1.hidden_nodes)
    related_conns_1 = filter(c -> c.origin == hidden_nodes[1].position || c.destination == hidden_nodes[1].position, mutated_genotype_1.connections)
    @test isempty(related_conns_1)

    # Test Case 2: Remove node at position 0.5
    mutated_genotype_2 = remove_node_2(rng, deepcopy(genotype), hidden_nodes[2])
    @test !in(hidden_nodes[2], mutated_genotype_2.hidden_nodes)
    related_conns_2 = filter(c -> c.origin == hidden_nodes[2].position || c.destination == hidden_nodes[2].position, mutated_genotype_2.connections)
    @test isempty(related_conns_2)

    # Test Case 3: Since there's no hidden_node_at_2 in our dummy, let's adapt this to remove an output node (position 1.0 for instance)
    mutated_genotype_3 = remove_node_2(rng, deepcopy(genotype), output_nodes[1])
    @test !in(output_nodes[1], [node.position for node in mutated_genotype_3.hidden_nodes])
    related_conns_3 = filter(c -> c.origin == output_nodes[1].position || c.destination == output_nodes[1].position, mutated_genotype_3.connections)
    @test isempty(related_conns_3)

    # Test Case 4: Create a random connection in the previously mutated genotype
end

using Test

#@testset "Redirect Connection Mutation Tests" begin
#    # Initialize your dummy genotype (which we previously defined)
#
#    # Test Case 1: Basic Redirection
#    selected_connection = genotype.connections[1] # For simplicity, let's select the first connection
#    mutated_genotype_1 = redirect_connection(rng, genotype, selected_connection, :outgoing)
#    # Check if the connection has been changed
#    @test !in(selected_connection, mutated_genotype_1.connections)
#    # Check that the rest of the network remains intact
#    @test setdiff(genotype.connections, [selected_connection]) ⊆ mutated_genotype_1.connections
#
#    # Test Case 2: Check for duplicate connections after redirection
#    # Try redirecting the same connection multiple times
#    mutated_genotype_2 = deepcopy(genotype)
#    for _ in 1:10
#        mutated_genotype_2 = redirect_connection(rng, mutated_genotype_2, mutated_genotype_2.connections[1], :outgoing)
#    end
#    # Ensure there are no duplicate connections
#    @test length(mutated_genotype_2.connections) == length(unique(mutated_genotype_2.connections))
#
#    # Test Case 3: Check if the connection end being redirected is random
#    # We will redirect the same connection multiple times and check how many times the origin changes versus the destination
#    origin_changes = 0
#    destination_changes = 0
#    mutated_genotype_3 = deepcopy(genotype)
#    println("genotype: $genotype")
#    old_genotype = deepcopy(genotype)
#    for _ in 1:100
#        println("genotype: $old_genotype")
#        mutated_genotype_3 = redirect_connection(
#            rng, 
#            old_genotype,
#            old_genotype.connections[1], 
#            :outgoing
#        )
#        println("----------------------------------")
#        println("geno: $genotype")
#        println("mutant: $mutated_genotype_3")
#        new_connection = setdiff(mutated_genotype_3.connections, old_genotype.connections)[1] # The changed connection
#        if new_connection.origin != selected_connection.origin
#            origin_changes += 1
#        elseif new_connection.destination != selected_connection.destination
#            destination_changes += 1
#        end
#        old_genotype = mutated_genotype_3
#    end
#    # We should see both origin and destination changes happening
#    @test origin_changes > 0
#    @test destination_changes == 0
#end
#
using StableRNGs
rng = StableRNG(42)
@testset "Stress Test: Multiple Mutations" begin
    # Take a deep copy of the original genotype
    mutated_genotype = deepcopy(genotype)
    
    # Number of iterations
    n_iterations = 1000
    mutator = GnarlNetworkMutator()
    gene_id_counter = Counter(11)

    for i = 1:n_iterations
        # Randomly select mutation type
        mutated_genotype = mutate(mutator, rng, gene_id_counter, mutated_genotype)

        # Consistency checks after every mutation

        # Ensure there's at most one connection per direction per node pair
        for node in get_neuron_positions(mutated_genotype)
            for other_node in get_neuron_positions(mutated_genotype)
                conn_count = count(c -> c.origin == node && c.destination == other_node, mutated_genotype.connections)
                @test conn_count <= 1
                if conn_count > 1
                    println("node: $node")
                    println("other_node: $other_node")
                    println("defective mutant re conn_count: $mutated_genotype")
                    return
                end
                # Check for the reversed direction if nodes are not the same
                if node != other_node
                    conn_count_rev = count(c -> c.origin == other_node && c.destination == node, mutated_genotype.connections)
                    @test conn_count_rev <= 1
                    if conn_count_rev > 1
                        println("node: $node")
                        println("other_node: $other_node")
                        println("defective mutant re conn_count_rev: $mutated_genotype")
                        return
                    end
                end
            end
        end

        # Ensure no connections link to the input or bias node
        @test !any(conn -> conn.destination <= 0.0, mutated_genotype.connections)

        if any(conn -> conn.destination <= 0.0, mutated_genotype.connections)
            println("defective mutant re link to input or bias: $mutated_genotype")
            return
        end

        # Ensure there are no connections to nonexistent nodes
        valid_positions = get_neuron_positions(mutated_genotype)
        @test all(conn -> conn.origin in valid_positions && conn.destination in valid_positions, mutated_genotype.connections)

    end
end
