
using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.BinomialFunctionGraphs
using CoEvo.Counters: step!
using CoEvo.Counters.Basic: BasicCounter
using CoEvo.Recombiners.HorizontalGeneTransfer
using ProgressBars





#recipient = SimpleFunctionGraphGenotype([
#    Node(-1, :INPUT, []),
#    Node(-2, :BIAS, []),
#    Node(1, :ADD, [
#        Edge(-1, 1.0, true), 
#        Edge(-2, 1.0, true)
#    ]),
#    Node(2, :RELU, [
#        Edge(3, 1.0, true), 
#    ]),
#    Node(3, :MINIMUM, [
#        Edge(3, 1.0, true), 
#        Edge(3, 1.0, true), 
#    ]),
#    Node(-3, :OUTPUT, [
#        Edge(1, 1.0, true),
#    ]),
#])
#donor = SimpleFunctionGraphGenotype([
#    Node(-1, :INPUT, []),
#    Node(-2, :BIAS, []),
#    Node(4, :MAXIMUM, [
#        Edge(-1, 1.0, true), 
#        Edge(-2, 1.0, true)
#    ]),
#    Node(-3, :OUTPUT, [
#        Edge(4, 1.0, true), 
#    ]),
#])
make_edges(source_id::Int, target_ids::Vector{Int}) =
    [Edge(source_id, target_id) for target_id in target_ids]

make_edges(source_id::Int, target_ids::Vector{Tuple{Int, Bool}}) =
    [Edge(source_id, target_id[1], target_id[2]) for target_id in target_ids]

recipient = SimpleFunctionGraphGenotype([
    Node(-1, :INPUT), Node(-2, :BIAS),
    Node(1, :ADD, make_edges(1, [-1, -2])),
    Node(2, :RELU, make_edges(2, [3])),
    Node(3, :MINIMUM, make_edges(3, [(3, true), (3, true)])),
    Node(-3, :OUTPUT, make_edges(-3, [1])),
])

donor = SimpleFunctionGraphGenotype([
    Node(-1, :INPUT), Node(-2, :BIAS),
    Node(4, :MAXIMUM, make_edges(4, [-1, -2])),
    Node(-3, :OUTPUT, make_edges(-3, [4])),
])



Base.@kwdef mutable struct DummyState <: State
    rng::StableRNG
    individual_id_counter::BasicCounter
    gene_id_counter::BasicCounter
    mutator::BinomialFunctionGraphMutator
end

mutator = BinomialFunctionGraphMutator(
    mutation_rates = Dict(
        "CLONE_NODE"    => 0.01,
        "REMOVE_NODE"   => 0.01,
        "MUTATE_NODE"   => 0.025,
        "MUTATE_BIAS"   => 0.05,
        "MUTATE_EDGE"   => 0.025,
        "MUTATE_WEIGHT" => 0.05,
    ),
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
    validate_genotype(recipient, "recipient")
    validate_genotype(donor, "donor")
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
#function relabel_node_ids!(nodes::Vector{<:Node}, counter::Counter)
#    # Create a map to track old to new ID mappings
#    id_map = Dict{Int, Int}()
#
#    # Update node IDs
#    for node in nodes
#        new_id = step!(counter)
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
#            step!(individual_id_counter), recipient.id, recipient.tag, genotype, 
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