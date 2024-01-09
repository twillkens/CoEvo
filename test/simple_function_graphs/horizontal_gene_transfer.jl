
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
using ProgressBars

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

struct HorizontalGeneTransferRecombiner <: Recombiner end

function relabel_node_ids!(nodes::Vector{<:SimpleFunctionGraphNode}, counter::Counter)
    # Create a map to track old to new ID mappings
    id_map = Dict{Int, Int}()

    # Update node IDs
    for node in nodes
        new_id = count!(counter)
        id_map[node.id] = new_id
        node.id = new_id
    end

    # Update edge target IDs
    for node in nodes
        for edge in node.edges
            if edge.target > 0
                edge.target = id_map[edge.target]
            end
        end
    end
end


function recombine(
    ::HorizontalGeneTransferRecombiner, 
    recipient::SimpleFunctionGraphGenotype,
    donor::SimpleFunctionGraphGenotype,
    state::State
)
    recipient = deepcopy(recipient)
    donor = deepcopy(donor)
    active_donor = minimize(donor)
    active_recipient = minimize(recipient)
    inactive_recipient = SimpleFunctionGraphGenotype([
        node for node in recipient.hidden_nodes if !(node in active_recipient.nodes)
    ])
    n_remove = get_size(inactive_recipient) - get_size(active_donor)
    if n_remove < 0
        genotype = recipient
    else
        [remove_node!(state.rng, inactive_recipient) for _ in 1:n_remove]
        relabel_node_ids!(active_donor.hidden_nodes, state.gene_id_counter)
        genotype = SimpleFunctionGraphGenotype([
            active_recipient.nodes ; inactive_recipient.hidden_nodes ; active_donor.hidden_nodes
        ])
    end
    return genotype
end

function recombine(
    recombiner::HorizontalGeneTransferRecombiner, parents::Vector{I}, state::State
)  where I <: ModesIndividual
    if length(parents) % 2 != 0
        error("The number of parents must be even for $(typeof(recombiner)).")
    end
    shuffle!(rng, parents)
    children = I[]
    for i in 1:2:length(parents)-1
        donor = parents[i]
        recipient = parents[i+1]
        genotype = recombine(
            recombiner,
            recipient.genotype,
            donor.genotype,
            state
        )
        child = ModesIndividual(
            count!(individual_id_counter), recipient.id, recipient.tag, genotype, 
        )
        push!(children, child)
    end
    return children
end

function recombine(
    recombiner::HorizontalGeneTransferRecombiner, 
    parents::Vector{<:ModesIndividual}, 
    state::State
)
    children = recombine(
        recombiner, state.rng, state.individual_id_counter, state.gene_id_counter, parents
    )
    return children
end

genotype = recombine(
    HorizontalGeneTransferRecombiner(), 
    StableRNG(0), 
    BasicCounter(9),
    donor, 
    recipient
)
println(genotype)
