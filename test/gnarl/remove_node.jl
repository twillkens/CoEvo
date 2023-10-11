using Test
include("../../src/CoEvo.jl")
using .CoEvo
using .Mutators.Types.GnarlNetworks: remove_node_2, redirect_or_replace_connection
using .Mutators.Types.GnarlNetworks: get_next_layer, get_previous_layer
using .Mutators.Types.GnarlNetworks: replace_connection
using .Mutators.Types.GnarlNetworks: redirect_connection, get_neuron_positions
using Random

using StableRNGs: StableRNG

# Sample data setup
function test_redirect_or_replace_connection()
    # Setting up a simple genotype for testing
    node1 = GnarlNetworkNodeGene(1, 0.25)
    node2 = GnarlNetworkNodeGene(2, 0.5)
    node3 = GnarlNetworkNodeGene(3, 0.75)
    conn1 = GnarlNetworkConnectionGene(1, 0.25, 0.5, 0.9)
    conn2 = GnarlNetworkConnectionGene(2, 0.5, 0.75, 0.8)
    geno = GnarlNetworkGenotype(1, 1, [node1, node2, node3], [conn1, conn2])
    
    # Running the redirect_or_replace function
    rng = Random.MersenneTwister(123)  # A random number generator
    result = redirect_or_replace_connection(rng, geno, 0.5, conn1, :incoming)
    
    # Asserting the expected behavior
    # Note: Depending on the complexity of your network, you might want to check specific connection properties.
    @test result.destination != conn1.destination
    
    println("Test passed!")
end

# Execute the test
test_redirect_or_replace_connection()

using StableRNGs
rng = StableRNG(42)

input_node = GnarlNetworkNodeGene(1, -1.0f0)
hidden_node1 = GnarlNetworkNodeGene(2, 0.5f0)
hidden_node2 = GnarlNetworkNodeGene(3, 0.7f0)
output_node = GnarlNetworkNodeGene(4, 1.0f0)

conn1 = GnarlNetworkConnectionGene(1, input_node.position, hidden_node1.position, 0.5f0)
conn2 = GnarlNetworkConnectionGene(2, hidden_node1.position, output_node.position, 0.5f0)

genotype = GnarlNetworkGenotype(1, 1, [hidden_node1, hidden_node2], [conn1, conn2])

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