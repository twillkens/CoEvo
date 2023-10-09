using Test
include("../../src/CoEvo.jl")
using .CoEvo
using .Mutators.Types.GnarlNetworks: remove_node_2, redirect_or_replace_connection, find_available_nodes, get_next_layer, get_previous_layer
using .Mutators.Types.GnarlNetworks: replace_connection

# Sample data setup
input_node = GnarlNetworkNodeGene(1, -1.0f0)
hidden_node1 = GnarlNetworkNodeGene(2, 0.5f0)
hidden_node2 = GnarlNetworkNodeGene(3, 0.7f0)
output_node = GnarlNetworkNodeGene(4, 1.0f0)

conn1 = GnarlNetworkConnectionGene(1, input_node.position, hidden_node1.position, 0.5f0)
conn2 = GnarlNetworkConnectionGene(2, hidden_node1.position, output_node.position, 0.5f0)

genotype = GnarlNetworkGenotype(1, 1, [hidden_node1, hidden_node2], [conn1, conn2])

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
    redirected_conn = redirect_or_replace_connection(genotype, conn1, :incoming)
    @test redirected_conn.origin == conn1.origin
    @test redirected_conn.destination in [hidden_node2.position, output_node.position]
end

# Test for removing nodes
@testset "Node Removal" begin
    mutated_genotype = remove_node_2(deepcopy(genotype), hidden_node1)
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
    redirected_conn = redirect_or_replace_connection(genotype_with_cascade, conn1, :incoming)
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
    redirected_conn = redirect_or_replace_connection(genotype, conn1, :outgoing)
    @test redirected_conn.origin != input_node.position
end

@testset "Node Removal Impact on Other Nodes" begin
    mutated_genotype = remove_node_2(deepcopy(genotype), hidden_node1)
    # Check if only the targeted node is removed and others remain unaffected
    @test !in(hidden_node1, mutated_genotype.hidden_nodes)
    @test in(hidden_node2, mutated_genotype.hidden_nodes)
end

@testset "Permissible Circular Connections" begin
    # Assuming nodes and genotype are initialized as before
    # Redirecting an outgoing connection from hidden_node1, and it's permissible to have it loop back to itself
    new_conn = redirect_or_replace_connection(genotype, conn2, :outgoing)
    @test new_conn.origin == new_conn.destination == hidden_node1.position
end