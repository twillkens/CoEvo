using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.SimpleFunctionGraphs
#using CoEvo.Mutators.FunctionGraphs: add_function as fg_add_function, remove_function as fg_remove_function
using CoEvo.Phenotypes.FunctionGraphs.Efficient
#using CoEvo.Phenotypes.FunctionGraphs.Basic


function identify_invalid_candidates(genotype::SimpleFunctionGraphGenotype, target_node_id::Int)
    visited = Set{Int}()
    invalid_candidates = Set{Int}(genotype.output_ids)

    function reverse_dfs(node_id::Int)
        if node_id in visited
            return
        end
        push!(visited, node_id)
        push!(invalid_candidates, node_id)
        for node in genotype.nodes
            for edge in node.edges
                # Check if the edge is non-recurrent and leads to the current node
                if !edge.is_recurrent && edge.target == node_id
                    reverse_dfs(node.id)
                end
            end
        end
    end

    reverse_dfs(target_node_id)
    return collect(invalid_candidates)
end

function has_cycle_nonrecurrent(genotype::SimpleFunctionGraphGenotype, start_node_id::Int)
    visited = Set{Int}()
    
    function reverse_dfs(node_id::Int, origin_id::Int)
        if node_id in visited
            return false
        end
        push!(visited, node_id)
        for node in genotype.nodes
            for edge in node.edges
                if !edge.is_recurrent && edge.target == node_id
                    if node.id == origin_id || reverse_dfs(node.id, origin_id)
                        return true
                    end
                end
            end
        end
        return false
    end

    return reverse_dfs(start_node_id, start_node_id)
end

function has_cycle_nonrecurrent(genotype::SimpleFunctionGraphGenotype)
    for node in genotype.nodes
        if has_cycle_nonrecurrent(genotype, node.id)
            return true
        end
    end
    return false
end

genotype_1 = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(1, :INPUT, []),
    SimpleFunctionGraphNode(2, :AND, [
        SimpleFunctionGraphEdge(1, 1.0, false), 
        SimpleFunctionGraphEdge(5, 1.0, true), 
    ]),
    SimpleFunctionGraphNode(3, :AND, [
        SimpleFunctionGraphEdge(2, 1.0, false), 
        SimpleFunctionGraphEdge(1, 1.0, false)
    ]),
    SimpleFunctionGraphNode(4, :AND, [
        SimpleFunctionGraphEdge(3, 1.0, false), 
        SimpleFunctionGraphEdge(6, 1.0, true)
    ]),
    SimpleFunctionGraphNode(5, :AND, [
        SimpleFunctionGraphEdge(3, 1.0, false), 
        SimpleFunctionGraphEdge(6, 1.0, true)
    ]),
    SimpleFunctionGraphNode(6, :NOT, [
        SimpleFunctionGraphEdge(3, 1.0, true), 
    ]),
    SimpleFunctionGraphNode(7, :OUTPUT, [
        SimpleFunctionGraphEdge(6, 1.0, false), 
    ]),
    SimpleFunctionGraphNode(8, :INPUT, []),
    SimpleFunctionGraphNode(9, :AND, [
        SimpleFunctionGraphEdge(9, 1.0, true), 
        SimpleFunctionGraphEdge(8, 1.0, false)
    ]),
    SimpleFunctionGraphNode(10, :FIZZ, [
        SimpleFunctionGraphEdge(9, 1.0, false), 
        SimpleFunctionGraphEdge(10, 1.0, true),
        SimpleFunctionGraphEdge(2, 1.0, true)
    ]),
])

# Define edges according to your structure
#edge1 = SimpleFunctionGraphEdge(target=2, weight=1.0, is_recurrent=false)
#edge2 = SimpleFunctionGraphEdge(target=3, weight=1.0, is_recurrent=false)
#edge3 = SimpleFunctionGraphEdge(target=4, weight=1.0, is_recurrent=false)
#
## Define nodes
#node1 = SimpleFunctionGraphNode(id=1, func=:f1, edges=[edge1])
#node2 = SimpleFunctionGraphNode(id=2, func=:f2, edges=[edge2])
#node3 = SimpleFunctionGraphNode(id=3, func=:f3, edges=[edge3])
#node4 = SimpleFunctionGraphNode(id=4, func=:f4, edges=[])

# Define the genotype

genotype_2 = SimpleFunctionGraphGenotype(nodes=[
    SimpleFunctionGraphNode(id=1, func=:f1, edges=[
        SimpleFunctionGraphEdge(target=2, weight=1.0, is_recurrent=false)
    ]),
    SimpleFunctionGraphNode(id=2, func=:f2, edges=[
        SimpleFunctionGraphEdge(target=3, weight=1.0, is_recurrent=false)
    ]),
    SimpleFunctionGraphNode(id=3, func=:f3, edges=[
        SimpleFunctionGraphEdge(target=4, weight=1.0, is_recurrent=false)
    ]),
    SimpleFunctionGraphNode(id=4, func=:f4, edges=[])
])

@test get_valid_nonrecurrent_edge_targets(genotype_2, 1) == [2, 3, 4]
@test get_valid_nonrecurrent_edge_targets(genotype_2, 2) == [3, 4]
@test get_valid_nonrecurrent_edge_targets(genotype_2, 3) == [4]
@test get_valid_nonrecurrent_edge_targets(genotype_2, 4) == Int[]

# Identify invalid candidates for Node 4
#invalid_candidates = identify_invalid_candidates(genotype, 4)

#println(invalid_candidates)

genotype_3 = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(1, :SELF, [
        SimpleFunctionGraphEdge(1, 1.0, true)
    ])
])

# Test for Node 1
#invalid_candidates_1 = identify_invalid_candidates(genotype_1, 1)

genotype_4 = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(1, :AND, [
        SimpleFunctionGraphEdge(2, 1.0, false)  # Non-recurrent input from Node 2
    ]),
    SimpleFunctionGraphNode(2, :AND, [
        SimpleFunctionGraphEdge(1, 1.0, true)  # Recurrent input from Node 1
    ])
])

genotype_5 = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(1, :AND, [SimpleFunctionGraphEdge(2, 1.0, true)]),
    SimpleFunctionGraphNode(2, :OR, [SimpleFunctionGraphEdge(3, 1.0, false), SimpleFunctionGraphEdge(1, 1.0, true)]),
    SimpleFunctionGraphNode(3, :NOT, [SimpleFunctionGraphEdge(4, 1.0, false)]),
    SimpleFunctionGraphNode(4, :XOR, [SimpleFunctionGraphEdge(5, 1.0, false)]),
    SimpleFunctionGraphNode(5, :NAND, [SimpleFunctionGraphEdge(6, 1.0, true)]),
    SimpleFunctionGraphNode(6, :NOR, [SimpleFunctionGraphEdge(7, 1.0, false), SimpleFunctionGraphEdge(5, 1.0, true)]),
    SimpleFunctionGraphNode(7, :XNOR, [SimpleFunctionGraphEdge(8, 1.0, false)]),
    SimpleFunctionGraphNode(8, :AND, [SimpleFunctionGraphEdge(9, 1.0, false)]),
    SimpleFunctionGraphNode(9, :OR, [SimpleFunctionGraphEdge(10, 1.0, false)]),
    SimpleFunctionGraphNode(10, :NOT, [])
])

genotype_6 = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(1, :AND, [SimpleFunctionGraphEdge(2, 1.0, false)]),
    SimpleFunctionGraphNode(2, :OR, [SimpleFunctionGraphEdge(3, 1.0, false)]),
    SimpleFunctionGraphNode(3, :NOT, [SimpleFunctionGraphEdge(4, 1.0, false)]),
    SimpleFunctionGraphNode(4, :XOR, [SimpleFunctionGraphEdge(5, 1.0, false)]),
    SimpleFunctionGraphNode(5, :NAND, [SimpleFunctionGraphEdge(6, 1.0, false)]),
    SimpleFunctionGraphNode(6, :NOR, [SimpleFunctionGraphEdge(1, 1.0, false), SimpleFunctionGraphEdge(7, 1.0, true)]),
    SimpleFunctionGraphNode(7, :XNOR, [SimpleFunctionGraphEdge(8, 1.0, false)]),
    SimpleFunctionGraphNode(8, :AND, [SimpleFunctionGraphEdge(9, 1.0, false)]),
    SimpleFunctionGraphNode(9, :OR, [SimpleFunctionGraphEdge(10, 1.0, false)]),
    SimpleFunctionGraphNode(10, :NOT, [])
])


# Test for Node 1
#invalid_candidates_2 = identify_invalid_candidates(genotype_2, 1)

using Random

# Define a simple RNG
rng = MersenneTwister(123)

# Define edges according to your structure
edge1 = SimpleFunctionGraphEdge(target=2, weight=1.0, is_recurrent=false)
edge2 = SimpleFunctionGraphEdge(target=3, weight=1.0, is_recurrent=false)

# Define nodes
node1 = SimpleFunctionGraphNode(id=1, func=:AND, edges=[edge1])
node2 = SimpleFunctionGraphNode(id=2, func=:AND, edges=[edge2])
node3 = SimpleFunctionGraphNode(id=3, func=:AND, edges=[])

# Define the genotype
genotype = SimpleFunctionGraphGenotype(nodes=[node1, node2, node3])

# Mutate the genotype
#mutate_edge_nonrecurrent!(rng, genotype)

# Output the mutated genotype for inspection
println(genotype)

genotype_nonrecurrent = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(1, :INPUT, []),
    SimpleFunctionGraphNode(2, :INPUT, []),
    SimpleFunctionGraphNode(3, :F, [
        SimpleFunctionGraphEdge(1, 1.0, false)
    ]),
    SimpleFunctionGraphNode(4, :F, [
        SimpleFunctionGraphEdge(1, 1.0, false)
    ]),
    SimpleFunctionGraphNode(5, :F, [
        SimpleFunctionGraphEdge(2, 1.0, false)
    ]),
    SimpleFunctionGraphNode(6, :F, [
        SimpleFunctionGraphEdge(4, 1.0, false),
        SimpleFunctionGraphEdge(7, 1.0, false)
    ]),
    SimpleFunctionGraphNode(7, :F, [
        SimpleFunctionGraphEdge(4, 1.0, false)
    ]),
    SimpleFunctionGraphNode(8, :F, [
        SimpleFunctionGraphEdge(4, 1.0, false)
    ]),
    SimpleFunctionGraphNode(9, :F, [
        SimpleFunctionGraphEdge(5, 1.0, false),
        SimpleFunctionGraphEdge(8, 1.0, false)
    ]),
    SimpleFunctionGraphNode(10, :F, [
        SimpleFunctionGraphEdge(7, 1.0, false),
        SimpleFunctionGraphEdge(11, 1.0, false)
    ]),
    SimpleFunctionGraphNode(11, :F, [
        SimpleFunctionGraphEdge(7, 1.0, false)
    ]),
    SimpleFunctionGraphNode(12, :F, [
        SimpleFunctionGraphEdge(8, 1.0, false),
        SimpleFunctionGraphEdge(9, 1.0, false),
    ]),
    SimpleFunctionGraphNode(13, :OUTPUT, [
        SimpleFunctionGraphEdge(12, 1.0, false),
    ]),
])
get_valid(g, id) = sort(get_valid_nonrecurrent_edge_targets(g, id))
@test get_valid(genotype_nonrecurrent, 1) == [2, 5]
@test get_valid(genotype_nonrecurrent, 2) == [1, 3, 4, 6, 7, 8, 10, 11]
@test get_valid(genotype_nonrecurrent, 3) == setdiff(genotype_nonrecurrent.node_ids, [3, 13])
@test get_valid(genotype_nonrecurrent, 4) == [1, 2, 3, 5]
@test get_valid(genotype_nonrecurrent, 5) == [1, 2, 3, 4, 6, 7, 8, 10, 11]
@test get_valid(genotype_nonrecurrent, 6) == [1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12]
@test get_valid(genotype_nonrecurrent, 7) == [1, 2, 3, 4, 5, 8, 9, 12]
@test get_valid(genotype_nonrecurrent, 8) == [1, 2, 3, 4, 5, 6, 7, 10, 11]
@test get_valid(genotype_nonrecurrent, 9) == [1, 2, 3, 4, 5, 6, 7, 8, 10, 11]
@test get_valid(genotype_nonrecurrent, 10) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12]
@test get_valid(genotype_nonrecurrent, 11) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 12]
@test get_valid(genotype_nonrecurrent, 12) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
@test get_valid(genotype_nonrecurrent, 13) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

using Random


# Randomly shuffle the nodes
shuffle!(genotype_nonrecurrent.nodes)

# Apply the sorting function
sort_by_execution_order!(genotype_nonrecurrent)

# Check the order of nodes
expected_order = [1, 2, 3, 4, 5, 7, 8, 6, 9, 11, 10, 12, 13]
sorted_order = [node.id for node in genotype_nonrecurrent.nodes]

# Test
@test sorted_order == expected_order
