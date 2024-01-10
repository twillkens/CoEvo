module HorizontalGeneTransfer

export HorizontalGeneTransferRecombiner

import ..Recombiners: recombine

using Random: AbstractRNG, shuffle!
using ...Counters: Counter, count!
using ...Individuals.Modes: ModesIndividual
using ..Recombiners: Recombiner
using ...Abstract.States: State
using ...Genotypes
using ...Genotypes.SimpleFunctionGraphs

include("remove.jl")

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

function get_n_reduce(n_recipient_inactive::Int, n_donor_active::Int)
    if n_donor_active >= n_recipient_inactive
        # Remove all inactive recipient material and reduce donor material to match
        n_remove_inactive = n_recipient_inactive
        n_remove_donor = n_donor_active - n_recipient_inactive
    else
        # Remove an amount of inactive recipient material equal to the donor material
        n_remove_inactive = n_donor_active
        n_remove_donor = 0
    end
    return (n_remove_inactive, n_remove_donor)
end


function recombine(
    ::HorizontalGeneTransferRecombiner, 
    original_recipient::SimpleFunctionGraphGenotype,
    original_donor::SimpleFunctionGraphGenotype,
    state::State
)
    # Random chance to return a copy of the original recipient
    if rand(state.rng) < 0.5
        return deepcopy(original_recipient)
    end

    # Deep copying the original genotypes
    recipient = deepcopy(original_recipient)
    donor = deepcopy(original_donor)

    # Minimizing the donor and recipient genotypes
    active_donor = minimize(donor)
    active_recipient = minimize(recipient)

    # Identifying inactive nodes in the recipient
    inactive_recipient = SimpleFunctionGraphGenotype([
        node for node in recipient.nodes if !(node in active_recipient.nodes)
    ])


    # Determine the number of nodes to remove using get_n_reduce
    n_remove_inactive, n_remove_donor = get_n_reduce(
        get_size(inactive_recipient), get_size(active_donor)
    )

    # Remove nodes from inactive recipient and active donor
    for _ in 1:n_remove_inactive
        remove_node!(state.rng, inactive_recipient)
    end
    for _ in 1:n_remove_donor
        remove_node!(state.rng, active_donor)
    end
    relabel_node_ids!(active_donor.hidden_nodes, state.gene_id_counter)

    # Combining genotypes
    genotype = SimpleFunctionGraphGenotype([
        active_recipient.nodes ; inactive_recipient.hidden_nodes ; active_donor.hidden_nodes
    ])

    # Checking if the size of the new genotype matches the original recipient's size
    if get_size(genotype) != get_size(original_recipient)
        println("original_recipient = ", original_recipient)
        println("original_donor = ", original_donor)
        println("genotype = ", genotype)
        throw(ErrorException("The size of the genotype has changed."))
    end

    return genotype
end


#function recombine(
#    ::HorizontalGeneTransferRecombiner, 
#    original_recipient::SimpleFunctionGraphGenotype,
#    original_donor::SimpleFunctionGraphGenotype,
#    state::State
#)
#    if rand(state.rng) < 0.5
#        return deepcopy(original_recipient)
#    end
#    original_recipent_size = get_size(original_recipient)
#    recipient = deepcopy(original_recipient)
#    donor = deepcopy(original_donor)
#    active_donor = minimize(donor)
#    active_recipient = minimize(recipient)
#    inactive_recipient = SimpleFunctionGraphGenotype([
#        node for node in recipient.hidden_nodes if !(node in active_recipient.nodes)
#    ])
#    n_donor_active = get_size(active_donor)
#    n_recipient_inactive = get_size(inactive_recipient)
#    n_remove = n_donor_active > n_recipient_inactive ? 0 : n_donor_active
#    if n_remove == 0
#        genotype = recipient
#    else
#        [remove_node!(state.rng, inactive_recipient) for _ in 1:n_remove]
#        relabel_node_ids!(active_donor.hidden_nodes, state.gene_id_counter)
#        genotype = SimpleFunctionGraphGenotype([
#            active_recipient.nodes ; inactive_recipient.hidden_nodes ; active_donor.hidden_nodes
#        ])
#    end
#    new_size = get_size(genotype)
#    if new_size != original_recipent_size
#        println("original_recipient = ", original_recipient)
#        println("original_donor = ", original_donor)
#        println("genotype = ", genotype)
#        throw(ErrorException("The size of the genotype has changed."))
#    end
#    return genotype
#end

function recombine(
    recombiner::HorizontalGeneTransferRecombiner, parents::Vector{I}, state::State
)  where I <: ModesIndividual
    if length(parents) % 2 != 0
        error("The number of parents must be even for $(typeof(recombiner)).")
    end
    shuffle!(state.rng, parents)
    children = I[]
    for recipient in parents
        #donor = parents[i]
        donors = Set(filter(individual -> individual.id != recipient.id, parents))
        donor = rand(state.rng, donors)
        genotype = recombine(
            recombiner,
            recipient.genotype,
            donor.genotype,
            state
        )
        child = ModesIndividual(
            count!(state.individual_id_counter), recipient.id, recipient.tag, genotype, 
        )
        push!(children, child)
    end
    return children
end


end