using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.BinomialFunctionGraphs
#using CoEvo.Mutators.FunctionGraphs: add_function as fg_add_function, remove_function as fg_remove_function
using CoEvo.Phenotypes.FunctionGraphs.Efficient
#using CoEvo.Phenotypes.FunctionGraphs.Basic



#genotype_nonrecurrent = SimpleFunctionGraphGenotype([
#    Node(1, :INPUT, []),
#    Node(2, :INPUT, []),
#    Node(3, :F, [
#        Edge(1, 1.0, false)
#    ]),
#    Node(4, :F, [
#        Edge(1, 1.0, false)
#    ]),
#    Node(5, :F, [
#        Edge(2, 1.0, false)
#    ]),
#    Node(6, :F, [
#        Edge(4, 1.0, false),
#        Edge(7, 1.0, false)
#    ]),
#    Node(7, :F, [
#        Edge(4, 1.0, false)
#    ]),
#    Node(8, :F, [
#        Edge(4, 1.0, false)
#    ]),
#    Node(9, :F, [
#        Edge(5, 1.0, false),
#        Edge(8, 1.0, false)
#    ]),
#    Node(10, :F, [
#        Edge(7, 1.0, false),
#        Edge(11, 1.0, false)
#    ]),
#    Node(11, :F, [
#        Edge(7, 1.0, false)
#    ]),
#    Node(12, :F, [
#        Edge(8, 1.0, false),
#        Edge(9, 1.0, false),
#    ]),
#    Node(13, :OUTPUT, [
#        Edge(12, 1.0, false),
#    ]),
#])
make_edges(source_id::Int, target_ids::Vector{Int}) =
    [Edge(source_id, target_id) for target_id in target_ids]

make_edges(source_id::Int, target_ids::Vector{Tuple{Int, Bool}}) =
    [Edge(source_id, target_id[1], target_id[2]) for target_id in target_ids]

genotype_nonrecurrent = SimpleFunctionGraphGenotype([
    Node(1, :INPUT), Node(2, :INPUT),
    Node(3, :F, make_edges(3, [1])),
    Node(4, :F, make_edges(4, [1])),
    Node(5, :F, make_edges(5, [2])),
    Node(6, :F, make_edges(6, [4, 7])),
    Node(7, :F, make_edges(7, [4])),
    Node(8, :F, make_edges(8, [4])),
    Node(9, :F, make_edges(9, [5, 8])),
    Node(10, :F, make_edges(10, [7, 11])),
    Node(11, :F, make_edges(11, [7])),
    Node(12, :F, make_edges(12, [8, 9])),
    Node(13, :OUTPUT, make_edges(13, [12])),
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
