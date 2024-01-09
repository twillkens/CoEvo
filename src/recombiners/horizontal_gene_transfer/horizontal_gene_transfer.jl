module HorizontalGeneTransfer

export HorizontalGeneTransferRecombiner

import ..Recombiners: recombine

using Random: AbstractRNG
using ...Counters: Counter, count!
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ..Recombiners: Recombiner
using ...Abstract.States: State

Base.@kwdef struct HorizontalGeneTransferRecombiner <: Recombiner end

using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes

function get_depth_dictionary(genotype::FunctionGraphGenotype)
    # find the "root nodes" of the genotype graph, which will comprise the input nodes
    # the bias nodes, and nodes that are disconnected from these but are still pointed to by
    # some other node.
    # for each node in the genotype, find the depth, which is the minimum distance 
    # to a root node when traversing through the input connections.
    # return a dictionary mapping node ids to their depths.
end

function remove_nodes_with_highest_depth(
    genotype::FunctionGraphGenotype, 
    depth_dictionary::Dict{Int, Int}, 
    n_remove::Int
)
    # remove the n_remove nodes with the highest depth
end

function recombine(
    ::HorizontalGeneTransferRecombiner, 
    rng::AbstractRNG,
    donor::FunctionGraphGenotype,
    recipient::FunctionGraphGenotype
)
    active_donor_material = minimize(donor)
    active_recipient_material = minimize(recipient)
    inactive_recipient_material = minimize(recipient)
    depth_dictionary = get_depth_dictionary(inactive_recipient_material)
    n_remove = get_size(recipient) - get_size(active_donor_material)
    remove_nodes_with_highest_depth!(inactive_recipient_material, depth_dictionary, n_remove)


end

function recombine(
    ::HorizontalGeneTransferRecombiner,
    ::AbstractRNG, 
    individual_id_counter::Counter, 
    parent_set::Set{<:BasicIndividual}
) 
    children = [
        BasicIndividual(count!(individual_id_counter), parent.genotype, [parent.id]) 
        for parent in parents
    ]
    return children
end

function recombine(
    ::HorizontalGeneTransferRecombiner, individual_id_counter::Counter, parents::Vector{<:ModesIndividual}
) 
    children = [
        ModesIndividual(
            count!(individual_id_counter), parent.id, parent.tag, parent.genotype,
        ) 
        for parent in parents
    ]
    #parent_ids = [parent.id for parent in parents]
    #children_ids = [child.id for child in children]
    #summaries = [(child_id, parent_id) for child_id in children_ids, parent_id in parent_ids]
    #println("recombiner_results = $summaries")
    return children
end

function recombine(recombiner::HorizontalGeneTransferRecombiner, parents::Vector{<:ModesIndividual}, state::State)
    children = recombine(recombiner, state.individual_id_counter, parents)
    return children
end

end