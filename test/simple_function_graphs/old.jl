
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
    Node(1, :INPUT, []),
    Node(2, :AND, [
        Edge(1, 1.0, false), 
        Edge(5, 1.0, true), 
    ]),
    Node(3, :AND, [
        Edge(2, 1.0, false), 
        Edge(1, 1.0, false)
    ]),
    Node(4, :AND, [
        Edge(3, 1.0, false), 
        Edge(6, 1.0, true)
    ]),
    Node(5, :AND, [
        Edge(3, 1.0, false), 
        Edge(6, 1.0, true)
    ]),
    Node(6, :NOT, [
        Edge(3, 1.0, true), 
    ]),
    Node(7, :OUTPUT, [
        Edge(6, 1.0, false), 
    ]),
    Node(8, :INPUT, []),
    Node(9, :AND, [
        Edge(9, 1.0, true), 
        Edge(8, 1.0, false)
    ]),
    Node(10, :FIZZ, [
        Edge(9, 1.0, false), 
        Edge(10, 1.0, true),
        Edge(2, 1.0, true)
    ]),
])

# Define edges according to your structure
#edge1 = Edge(target=2, weight=1.0, is_recurrent=false)
#edge2 = Edge(target=3, weight=1.0, is_recurrent=false)
#edge3 = Edge(target=4, weight=1.0, is_recurrent=false)
#
## Define nodes
#node1 = Node(id=1, func=:f1, edges=[edge1])
#node2 = Node(id=2, func=:f2, edges=[edge2])
#node3 = Node(id=3, func=:f3, edges=[edge3])
#node4 = Node(id=4, func=:f4, edges=[])

# Define the genotype

genotype_2 = SimpleFunctionGraphGenotype(nodes=[
    Node(id=1, func=:f1, edges=[
        Edge(target=2, weight=1.0, is_recurrent=false)
    ]),
    Node(id=2, func=:f2, edges=[
        Edge(target=3, weight=1.0, is_recurrent=false)
    ]),
    Node(id=3, func=:f3, edges=[
        Edge(target=4, weight=1.0, is_recurrent=false)
    ]),
    Node(id=4, func=:f4, edges=[])
])

@test get_valid_nonrecurrent_edge_targets(genotype_2, 1) == [2, 3, 4]
@test get_valid_nonrecurrent_edge_targets(genotype_2, 2) == [3, 4]
@test get_valid_nonrecurrent_edge_targets(genotype_2, 3) == [4]
@test get_valid_nonrecurrent_edge_targets(genotype_2, 4) == Int[]

# Identify invalid candidates for Node 4
#invalid_candidates = identify_invalid_candidates(genotype, 4)

#println(invalid_candidates)

genotype_3 = SimpleFunctionGraphGenotype([
    Node(1, :SELF, [
        Edge(1, 1.0, true)
    ])
])

# Test for Node 1
#invalid_candidates_1 = identify_invalid_candidates(genotype_1, 1)

genotype_4 = SimpleFunctionGraphGenotype([
    Node(1, :AND, [
        Edge(2, 1.0, false)  # Non-recurrent input from Node 2
    ]),
    Node(2, :AND, [
        Edge(1, 1.0, true)  # Recurrent input from Node 1
    ])
])

genotype_5 = SimpleFunctionGraphGenotype([
    Node(1, :AND, [Edge(2, 1.0, true)]),
    Node(2, :OR, [Edge(3, 1.0, false), Edge(1, 1.0, true)]),
    Node(3, :NOT, [Edge(4, 1.0, false)]),
    Node(4, :XOR, [Edge(5, 1.0, false)]),
    Node(5, :NAND, [Edge(6, 1.0, true)]),
    Node(6, :NOR, [Edge(7, 1.0, false), Edge(5, 1.0, true)]),
    Node(7, :XNOR, [Edge(8, 1.0, false)]),
    Node(8, :AND, [Edge(9, 1.0, false)]),
    Node(9, :OR, [Edge(10, 1.0, false)]),
    Node(10, :NOT, [])
])

genotype_6 = SimpleFunctionGraphGenotype([
    Node(1, :AND, [Edge(2, 1.0, false)]),
    Node(2, :OR, [Edge(3, 1.0, false)]),
    Node(3, :NOT, [Edge(4, 1.0, false)]),
    Node(4, :XOR, [Edge(5, 1.0, false)]),
    Node(5, :NAND, [Edge(6, 1.0, false)]),
    Node(6, :NOR, [Edge(1, 1.0, false), Edge(7, 1.0, true)]),
    Node(7, :XNOR, [Edge(8, 1.0, false)]),
    Node(8, :AND, [Edge(9, 1.0, false)]),
    Node(9, :OR, [Edge(10, 1.0, false)]),
    Node(10, :NOT, [])
])


# Test for Node 1
#invalid_candidates_2 = identify_invalid_candidates(genotype_2, 1)

using Random

# Define a simple RNG
rng = MersenneTwister(123)

# Define edges according to your structure
edge1 = Edge(target=2, weight=1.0, is_recurrent=false)
edge2 = Edge(target=3, weight=1.0, is_recurrent=false)

# Define nodes
node1 = Node(id=1, func=:AND, edges=[edge1])
node2 = Node(id=2, func=:AND, edges=[edge2])
node3 = Node(id=3, func=:AND, edges=[])

# Define the genotype
genotype = SimpleFunctionGraphGenotype(nodes=[node1, node2, node3])

# Mutate the genotype
#mutate_edge_nonrecurrent!(rng, genotype)

# Output the mutated genotype for inspection
println(genotype)