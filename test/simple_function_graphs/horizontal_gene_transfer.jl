
using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.SimpleFunctionGraphs
using CoEvo.Phenotypes.FunctionGraphs.Efficient
using CoEvo.Counters: count!
using CoEvo.Counters.Basic: BasicCounter
using CoEvo.Recombiners.HorizontalGeneTransfer
using ProgressBars


function get_depth_dictionary(genotype::SimpleFunctionGraphGenotype)
    # Create a dictionary to store node depths
    depth_dict = Dict{Int, Int}()

    # Identify nodes that have edges pointing to them
    nodes_with_incoming_edges = Set{Int}()
    for node in genotype.nodes
        for edge in node.edges
            push!(nodes_with_incoming_edges, edge.target)
        end
    end

    # Root nodes are those not in nodes_with_incoming_edges
    root_nodes = [node.id for node in genotype.nodes if !(node.id in nodes_with_incoming_edges)]

    # Set depth of root nodes to 0 and others to a large number
    for node in genotype.nodes
        depth_dict[node.id] = node.id in root_nodes ? 0 : typemax(Int)
    end

    # Function to recursively update the depth of connected nodes
    function update_depth(node_id, current_depth, visited)
        if node_id in visited
            return
        end
        push!(visited, node_id)
        depth_dict[node_id] = min(depth_dict[node_id], current_depth)
        for edge in genotype.nodes[findfirst(n -> n.id == node_id, genotype.nodes)].edges
            update_depth(edge.target, current_depth + 1, visited)
        end
    end

    # Update depths starting from the root nodes
    for root_id in root_nodes
        update_depth(root_id, 0, Set{Int}())
    end

    return depth_dict
end
#function get_depth_dictionary(genotype::SimpleFunctionGraphGenotype)
#    # Create a dictionary to store node depths
#    depth_dict = Dict{Int, Int}()
#
#    # Initialize all node depths to a large number
#    for node in genotype.nodes
#        depth_dict[node.id] = typemax(Int)
#    end
#
#    # Identify nodes that are targets of edges
#    target_nodes = Set{Int}([edge.target for node in genotype.nodes for edge in node.edges])
#
#    # Identify root nodes (nodes that are not targets)
#    root_nodes = [node.id for node in genotype.nodes if !(node.id in target_nodes)]
#
#    # Set depth of root nodes to 0
#    for root_id in root_nodes
#        depth_dict[root_id] = 0
#    end
#
#    # Function to recursively update the depth of connected nodes
#    function update_depth(node_id, current_depth)
#        for edge in genotype.nodes[findfirst(n -> n.id == node_id, genotype.nodes)].edges
#            if depth_dict[edge.target] > current_depth + 1
#                depth_dict[edge.target] = current_depth + 1
#                update_depth(edge.target, current_depth + 1)
#            end
#        end
#    end
#
#    # Update depths starting from the root nodes
#    for root_id in root_nodes
#        update_depth(root_id, 0)
#    end
#
#    return depth_dict
#end

genotype = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(1, :INPUT, []),
    SimpleFunctionGraphNode(2, :INPUT, []),
    SimpleFunctionGraphNode(3, :NAND, [
        SimpleFunctionGraphEdge(1, 1.0, false), 
        SimpleFunctionGraphEdge(2, 1.0, false)
    ]),
    SimpleFunctionGraphNode(4, :OR, [
        SimpleFunctionGraphEdge(1, 1.0, false), 
        SimpleFunctionGraphEdge(2, 1.0, false)
    ]),
    SimpleFunctionGraphNode(5, :AND, [
        SimpleFunctionGraphEdge(3, 1.0, false), 
        SimpleFunctionGraphEdge(4, 1.0, false)
    ]),
    SimpleFunctionGraphNode(6, :OUTPUT, [
        SimpleFunctionGraphEdge(5, 1.0, false)
    ])
])


recipient = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(-1, :INPUT, []),
    SimpleFunctionGraphNode(-2, :BIAS, []),
    SimpleFunctionGraphNode(1, :ADD, [
        SimpleFunctionGraphEdge(-1, 1.0, true), 
        SimpleFunctionGraphEdge(-2, 1.0, true)
    ]),
    SimpleFunctionGraphNode(2, :RELU, [
        SimpleFunctionGraphEdge(3, 1.0, true), 
    ]),
    SimpleFunctionGraphNode(3, :MINIMUM, [
        SimpleFunctionGraphEdge(3, 1.0, true), 
        SimpleFunctionGraphEdge(3, 1.0, true), 
    ]),
    SimpleFunctionGraphNode(-3, :OUTPUT, [
        SimpleFunctionGraphEdge(1, 1.0, true),
    ]),
])
donor = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(-1, :INPUT, []),
    SimpleFunctionGraphNode(-2, :BIAS, []),
    SimpleFunctionGraphNode(4, :MAXIMUM, [
        SimpleFunctionGraphEdge(-1, 1.0, true), 
        SimpleFunctionGraphEdge(-2, 1.0, true)
    ]),
    SimpleFunctionGraphNode(-3, :OUTPUT, [
        SimpleFunctionGraphEdge(4, 1.0, true), 
    ]),
])

mutator = SimpleFunctionGraphMutator()

Base.@kwdef mutable struct DummyState <: State
    rng::StableRNG
    individual_id_counter::BasicCounter
    gene_id_counter::BasicCounter
    mutator::SimpleFunctionGraphMutator
end

mutator = SimpleFunctionGraphMutator(
    max_mutations = 10,
    n_mutations_decay_rate = 0.5,
    recurrent_edge_probability = 0.5,
    mutation_weights = Dict(
        :add_node! => 1.0,
        :remove_node! => 1.0,
        :mutate_node! => 1.0,
        :mutate_edge! => 1.0,
    ),
    noise_std = 0.1,
    validate_genotypes = true
) 

state = DummyState(
    StableRNG(0),
    BasicCounter(3),
    BasicCounter(10),
    mutator
)

for i in 1:10_000
    mutate!(mutator, recipient, state)
    mutate!(mutator, donor, state)
    recipent = recombine(HorizontalGeneTransferRecombiner(), recipient, donor, state)
    validate_genotype(recipient, :recipient)
    validate_genotype(donor, :donor)
end
    


#genotype = recombine(
#    HorizontalGeneTransferRecombiner(), 
#    StableRNG(0), 
#    BasicCounter(9),
#    donor, 
#    recipient
#)
#println(genotype)

#struct HorizontalGeneTransferRecombiner <: Recombiner end
#function relabel_node_ids!(nodes::Vector{<:SimpleFunctionGraphNode}, counter::Counter)
#    # Create a map to track old to new ID mappings
#    id_map = Dict{Int, Int}()
#
#    # Update node IDs
#    for node in nodes
#        new_id = count!(counter)
#        id_map[node.id] = new_id
#        node.id = new_id
#    end
#
#    # Update edge target IDs
#    for node in nodes
#        for edge in node.edges
#            if edge.target > 0
#                edge.target = id_map[edge.target]
#            end
#        end
#    end
#end
#
#
#function recombine(
#    ::HorizontalGeneTransferRecombiner, 
#    recipient::SimpleFunctionGraphGenotype,
#    donor::SimpleFunctionGraphGenotype,
#    state::State
#)
#    recipient = deepcopy(recipient)
#    donor = deepcopy(donor)
#    active_donor = minimize(donor)
#    active_recipient = minimize(recipient)
#    inactive_recipient = SimpleFunctionGraphGenotype([
#        node for node in recipient.hidden_nodes if !(node in active_recipient.nodes)
#    ])
#    n_remove = get_size(inactive_recipient) - get_size(active_donor)
#    if n_remove < 0
#        genotype = recipient
#    else
#        [remove_node!(state.rng, inactive_recipient) for _ in 1:n_remove]
#        relabel_node_ids!(active_donor.hidden_nodes, state.gene_id_counter)
#        genotype = SimpleFunctionGraphGenotype([
#            active_recipient.nodes ; inactive_recipient.hidden_nodes ; active_donor.hidden_nodes
#        ])
#    end
#    return genotype
#end
#
#function recombine(
#    recombiner::HorizontalGeneTransferRecombiner, parents::Vector{I}, state::State
#)  where I <: ModesIndividual
#    if length(parents) % 2 != 0
#        error("The number of parents must be even for $(typeof(recombiner)).")
#    end
#    shuffle!(rng, parents)
#    children = I[]
#    for i in 1:2:length(parents)-1
#        donor = parents[i]
#        recipient = parents[i+1]
#        genotype = recombine(
#            recombiner,
#            recipient.genotype,
#            donor.genotype,
#            state
#        )
#        child = ModesIndividual(
#            count!(individual_id_counter), recipient.id, recipient.tag, genotype, 
#        )
#        push!(children, child)
#    end
#    return children
#end
#
#function recombine(
#    recombiner::HorizontalGeneTransferRecombiner, 
#    parents::Vector{<:ModesIndividual}, 
#    state::State
#)
#    children = recombine(
#        recombiner, state.rng, state.individual_id_counter, state.gene_id_counter, parents
#    )
#    return children
#end