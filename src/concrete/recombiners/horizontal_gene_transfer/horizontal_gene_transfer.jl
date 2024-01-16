module HorizontalGeneTransfer

export HorizontalGeneTransferRecombiner

import ....Interfaces: recombine

using Random: shuffle!
using ....Abstract
using ....Interfaces
using ....Interfaces: step!
using ...Individuals.Modes: ModesIndividual
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: validate_genotype, relabel_node_ids!
using ...Genotypes.FunctionGraphs: add_node!, remove_node!, mutate_node!, mutate_edge!

Base.@kwdef struct HorizontalGeneTransferRecombiner <: Recombiner 
    transfer_probability::Float64 = 0.5
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
    recombiner::HorizontalGeneTransferRecombiner, 
    original_recipient::FunctionGraphGenotype,
    original_donor::FunctionGraphGenotype,
    state::State
)
    # Random chance to return a copy of the original recipient
    if rand(state.rng) < recombiner.transfer_probability
        return deepcopy(original_recipient)
    end
    #println("RNG WITHIN RECOMBINE = $(state.rng.state)")

    # Deep copying the original genotypes
    recipient = deepcopy(original_recipient)
    donor = deepcopy(original_donor)

    # Minimizing the donor and recipient genotypes
    active_donor = minimize(donor)
    active_recipient = minimize(recipient)

    # Identifying inactive nodes in the recipient
    inactive_recipient = FunctionGraphGenotype([
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
    #println("RNG AFTER REMOVE NODES = $(state.rng.state)")
    relabel_node_ids!(active_donor, state.reproducer.gene_id_counter)

    # Combining genotypes
    genotype = FunctionGraphGenotype([
        active_recipient.nodes ; inactive_recipient.hidden_nodes ; active_donor.hidden_nodes
    ])

    # Checking if the size of the new genotype matches the original recipient's size
    if get_size(genotype) != get_size(original_recipient)
        println("original_recipient = ", original_recipient)
        println("original_donor = ", original_donor)
        println("genotype = ", genotype)
        error("The size of the genotype has changed.")
    end

    return genotype
end

function recombine(
    recombiner::HorizontalGeneTransferRecombiner, parents::Vector{I}, state::State
)  where I <: ModesIndividual
    if length(parents) % 2 != 0
        error("The number of parents must be even for $(typeof(recombiner)).")
    end
    shuffle!(state.rng, parents)
    children = I[]
    for recipient in parents
        donors = filter(individual -> individual.id != recipient.id, parents)
        donor = rand(state.rng, donors)
        #println("RNG AFTER SELECT DONOR = $(state.rng.state)")
        full_genotype = recombine(
            recombiner, recipient.full_genotype, donor.full_genotype, state
        )
        sort!(full_genotype.nodes, by = x -> x.id)
        #println("RNG AFTER RECOMBINE = $(state.rng.state)")
        new_id = step!(state.reproducer.individual_id_counter)
        minimized_genotype = minimize(full_genotype)
        sort!(minimized_genotype.nodes, by = x -> x.id)
        phenotype = create_phenotype(state.reproducer.phenotype_creator, new_id, minimized_genotype)
        child = ModesIndividual(
            id = new_id,
            parent_id = recipient.id, 
            tag = recipient.tag, 
            full_genotype = full_genotype, 
            minimized_genotype = minimized_genotype,
            phenotype = phenotype,
        )
        push!(children, child)
    end
    return children
end


end