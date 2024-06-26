using Test

@testset "Remove Node" begin

using CoEvo

using Random
using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Concrete.Counters.Basic: BasicCounter
using CoEvo.Concrete.Genotypes.GnarlNetworks
using CoEvo.Concrete.Phenotypes.GnarlNetworks
using CoEvo.Concrete.Mutators.GnarlNetworks


using StableRNGs
random_number_generator = StableRNG(43)

input_node = NodeGene(1, -1.0f0)
hidden_node1 = NodeGene(2, 0.5f0)
hidden_node2 = NodeGene(3, 0.7f0)
output_node = NodeGene(4, 1.0f0)

conn1 = ConnectionGene(1, input_node.position, hidden_node1.position, 0.5f0)
conn2 = ConnectionGene(2, hidden_node1.position, output_node.position, 0.5f0)

genotype = GnarlNetworkGenotype(1, 1, [hidden_node1, hidden_node2], [conn1, conn2])

@testset "Stress Test: Multiple Mutations" begin
    # Take a deep copy of the original genotype
    mutated_genotype = deepcopy(genotype)
    
    # Number of iterations
    n_iterations = 1000
    mutator = GnarlNetworkMutator()
    gene_id_counter = BasicCounter(11)

    problematic_pairs = []
    problematic_links = []
    problematic_nonexistent_nodes = []

    for i = 1:n_iterations
        # Randomly select mutation type
        mutated_genotype = mutate(
            mutator, random_number_generator, gene_id_counter, mutated_genotype
        )

        # Consistency checks after every mutation

        # Ensure there's at most one connection per direction per node pair
        for node in get_neuron_positions(mutated_genotype)
            for other_node in get_neuron_positions(mutated_genotype)
                conn_count = count(
                    connection -> connection.origin == node && 
                                  connection.destination == other_node, 
                    mutated_genotype.connections
                )
                if conn_count > 1
                    push!(problematic_pairs, (node, other_node))
                    println("node: $node")
                    println("other_node: $other_node")
                    println("defective mutant re conn_count: $mutated_genotype")
                    return
                end
                # Check for the reversed direction if nodes are not the same
                if node != other_node
                    conn_count_reversed = count(
                        connection -> connection.origin == other_node && 
                                      connection.destination == node, 
                        mutated_genotype.connections
                    )
                    if conn_count_reversed > 1
                        push!(problematic_pairs, (node, other_node))
                        println("node: $node")
                        println("other_node: $other_node")
                        println("defective mutant re conn_count_rev: $mutated_genotype")
                        return
                    end
                end
            end
        end


        if any(conn -> conn.destination <= 0.0, mutated_genotype.connections)
            push!(problematic_links, mutated_genotype)
        end

        valid_positions = get_neuron_positions(mutated_genotype)
        if !all(conn -> conn.origin in valid_positions && conn.destination in valid_positions, mutated_genotype.connections)
            push!(problematic_nonexistent_nodes, mutated_genotype)
        end
    end

    @test isempty(problematic_pairs)
    @test isempty(problematic_links)
    @test isempty(problematic_nonexistent_nodes)
end

end