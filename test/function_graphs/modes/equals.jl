import Base: ==, hash

using CoEvo
using CoEvo.Names
using CoEvo.Configurations.PredictionGame
using CoEvo.Genotypes.FunctionGraphs
using Test

function depth_first_search!(
    genotype::FunctionGraphGenotype, 
    node_id::Int, 
    visited::Dict{Int, Bool}, 
    label_sequence::Vector{String}
)
    func_string = string(genotype.nodes[node_id].func, "_")
    push!(label_sequence, func_string)
    visited[node_id] = true
    for connection in genotype.nodes[node_id].input_connections
        if !visited[connection.input_node_id]
            node_id = connection.input_node_id
            depth_first_search!(genotype, node_id, visited, label_sequence)
        end
    end
end

function get_label_sequence(genotype::FunctionGraphGenotype)
    visited = Dict{Int, Bool}([(id, false) for id in keys(genotype.nodes)])
    label_sequence = String[]
    for output_id in genotype.output_node_ids
        depth_first_search!(genotype, output_id, visited, label_sequence)
    end
    label_sequence = join(label_sequence, "_")
    return label_sequence
end

function ==(genotype_1::FunctionGraphGenotype, genotype_2::FunctionGraphGenotype)
    if length(genotype_1.nodes) != length(genotype_2.nodes)
        return false
    end
    label_sequence_1 = get_label_sequence(genotype_1)
    label_sequence_2 = get_label_sequence(genotype_2)
    return label_sequence_1 == label_sequence_2
end

function hash(genotype::FunctionGraphGenotype, h::UInt)
    # Helper function for depth-first search to create a label sequence string
    label_sequence = get_label_sequence(genotype)
    # Combine the hash of the label sequence string with the provided hash seed
    return hash(label_sequence, h)
end

genotype_1 = FunctionGraphGenotype(
    input_node_ids = [0],
    bias_node_ids = Int[],
    hidden_node_ids = [1, 2, 3, 4, 5],
    output_node_ids = [6],
    nodes = Dict(
        0 => FunctionGraphNode(0, :INPUT, []),
        1 => FunctionGraphNode(1, :IDENTITY, [
            FunctionGraphConnection(0, 1.0, false)
        ]),
        2 => FunctionGraphNode(2, :IDENTITY, [
            FunctionGraphConnection(1, 1.0, true)
        ]),
        3 => FunctionGraphNode(3, :MAXIMUM, [
            FunctionGraphConnection(1, 1.0, false),
            FunctionGraphConnection(5, 1.0, true), 
        ]),
        4 => FunctionGraphNode(4, :MULTIPLY, [
            FunctionGraphConnection(2, 1.0, true), 
            FunctionGraphConnection(3, 1.0, true)
        ]),
        5 => FunctionGraphNode(5, :ADD, [
            FunctionGraphConnection(3, 1.0, false), 
            FunctionGraphConnection(4, 1.0, false)
        ]),
        6 => FunctionGraphNode(6, :OUTPUT, [
            FunctionGraphConnection(5, 1.0, false)
        ]),
    ),
    n_nodes_per_output = 1
)

genotype_2 = FunctionGraphGenotype(
    input_node_ids = [1, 2], 
    bias_node_ids = [3],
    hidden_node_ids = [4, 5],
    output_node_ids = [6],
    nodes = Dict(
        1 => FunctionGraphNode(1, :INPUT, []),
        2 => FunctionGraphNode(2, :INPUT, []),
        3 => FunctionGraphNode(3, :BIAS, []),
        4 => FunctionGraphNode(4, :ADD, [
            FunctionGraphConnection(1, 1.0, false), 
            FunctionGraphConnection(3, 1.0, false)
        ]),
        5 => FunctionGraphNode(5, :ADD, [
            FunctionGraphConnection(2, 1.0, false), 
            FunctionGraphConnection(4, 1.0, false)
        ]),
        6 => FunctionGraphNode(6, :OUTPUT, [
            FunctionGraphConnection(5, 1.0, false)
        ])
    ),
    n_nodes_per_output = 1
)

genotype_3 = FunctionGraphGenotype(
    input_node_ids = [0],
    bias_node_ids = Int[],
    hidden_node_ids = [11, 22, 3, 4, 5],
    output_node_ids = [6],
    nodes = Dict(
        0 => FunctionGraphNode(0, :INPUT, []),
        11 => FunctionGraphNode(11, :IDENTITY, [
            FunctionGraphConnection(0, 1.0, false)
        ]),
        22 => FunctionGraphNode(22, :IDENTITY, [
            FunctionGraphConnection(11, 1.0, true)
        ]),
        3 => FunctionGraphNode(3, :MAXIMUM, [
            FunctionGraphConnection(11, 1.0, false),
            FunctionGraphConnection(5, 1.0, true), 
        ]),
        4 => FunctionGraphNode(4, :MULTIPLY, [
            FunctionGraphConnection(22, 1.0, true), 
            FunctionGraphConnection(3, 1.0, true)
        ]),
        5 => FunctionGraphNode(5, :ADD, [
            FunctionGraphConnection(3, 1.0, false), 
            FunctionGraphConnection(4, 1.0, false)
        ]),
        6 => FunctionGraphNode(6, :OUTPUT, [
            FunctionGraphConnection(5, 1.0, false)
        ]),
    ),
    n_nodes_per_output = 1
)
# Start of the test suite
@testset "FunctionGraphGenotype Structural Equality Tests" begin
    @testset "Comparing Different Genotypes" begin
        # Test 1: Comparing first and second genotypes (Expected: false)
        @test genotype_1 != genotype_2

        # Test 3: Comparing second and third genotypes (Expected: false)
        @test genotype_2 != genotype_3
    end

    @testset "Comparing Identical Genotypes" begin
        # Test 2: Comparing first and third genotypes (Expected: true)
        @test genotype_1 == genotype_3

        # Additional Test: Comparing a genotype with itself (Expected: true)
        @test genotype_1 == genotype_1
    end
end

# Continuing from your previous code

@testset "FunctionGraphGenotype Hash Function Tests" begin
    @testset "Hash Consistency for Identical Genotypes" begin
        # Test to ensure identical genotypes produce the same hash
        @test hash(genotype_1, UInt(0x12345678)) == hash(genotype_3, UInt(0x12345678)) # Expected: true, as genotype_1 and genotype_3 are structurally identical
    end

    @testset "Hash Uniqueness for Different Genotypes" begin
        # Test to ensure different genotypes produce different hashes
        @test hash(genotype_1, UInt(0x12345678)) != hash(genotype_2, UInt(0x12345678)) # Expected: true, as genotype_1 and genotype_2 are structurally different
    end
end

using Test

@testset "FunctionGraphGenotype Set Operations Tests" begin
    @testset "Creating and Modifying Sets" begin
        # Test 1: Creating a set with unique genotypes
        set1 = Set([genotype_1, genotype_2])
        @test length(set1) == 2

        # Test 2: Adding a genotype to a set
        push!(set1, genotype_3) # genotype_3 is identical to genotype_1
        @test length(set1) == 2 # Length should remain 2 as genotype_1 and genotype_3 are identical

        # Test 3: Removing a genotype from a set
        delete!(set1, genotype_1)
        @test length(set1) == 1
    end

    @testset "Set Union, Intersection, and Difference" begin
        set2 = Set([genotype_1, genotype_3]) # Contains identical genotypes
        set3 = Set([genotype_2])

        # Test 4: Union of sets
        union_set = union(set2, set3)
        @test length(union_set) == 2

        # Test 5: Intersection of sets
        intersection_set = intersect(set2, set3)
        @test isempty(intersection_set)

        # Test 6: Difference of sets
        difference_set = setdiff(set2, set3)
        @test length(difference_set) == 1
    end
end
