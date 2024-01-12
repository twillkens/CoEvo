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
using ...Genotypes.SimpleFunctionGraphs: validate_genotype, relabel_node_ids!
using ...Genotypes.SimpleFunctionGraphs: add_node!, remove_node!, mutate_node!, mutate_edge!

struct HorizontalGeneTransferRecombiner <: Recombiner end


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
        node for node in recipient.nodes if !(node in active_recipient.hidden_nodes)
    ])


    # Determine the number of nodes to remove using get_n_reduce
    n_remove_inactive, n_remove_donor = get_n_reduce(
        get_size(inactive_recipient), get_size(active_donor)
    )

    # Remove nodes from inactive recipient and active donor
    for _ in 1:n_remove_inactive
        remove_node!(inactive_recipient, state)
    end
    for _ in 1:n_remove_donor
        remove_node!(active_donor, state)
    end
    relabel_node_ids!(active_donor, state.gene_id_counter)

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
    for node in genotype.nodes
        for edge in node.edges
            if !edge.is_recurrent && edge.target == node.id
                println("original_genotype = ", original_recipient)
                println("original_donor = ", original_donor)
                println("genotype = ", genotype)
                throw(ErrorException("RECOMBINER Edge to self is non-recurrent"))
            end
        end
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