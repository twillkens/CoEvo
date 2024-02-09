module Clone

export CloneRecombiner

import ....Interfaces: recombine

using Random: AbstractRNG
using ....Abstract
using ....Interfaces: step!
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual

Base.@kwdef struct CloneRecombiner <: Recombiner end

function recombine(::CloneRecombiner, individual::Individual, state::State)
    child = deepcopy(individual)
    child.id = step!(state.reproducer.individual_id_counter)
    child.parent_id = individual.id
    child.phenotype.id = child.id
    return child
end

function recombine(recombiner::CloneRecombiner, parents::Vector{<:Individual}, state::State)
    children = [recombine(recombiner, parent, state) for parent in parents]
    return children
end

function recombine(recombiner::CloneRecombiner, selections::Vector{<:Selection}, state::State)
    if any([length(selection.records) != 1 for selection in selections])
        error("CloneRecombiner requires exactly one parent per selection")
    end
    parents = [first(selection.records).individual for selection in selections]
    children = recombine(recombiner, parents, state)
    return children
end

#function recombine(
#    ::CloneRecombiner, individual_id_counter::Counter, parents::Vector{<:ModesIndividual}
#) 
#    children = [
#        ModesIndividual(
#            step!(individual_id_counter), parent.id, parent.tag, parent.genotype,
#        ) 
#        for parent in parents
#    ]
#    #parent_ids = [parent.id for parent in parents]
#    #children_ids = [child.id for child in children]
#    #summaries = [(child_id, parent_id) for child_id in children_ids, parent_id in parent_ids]
#    #println("recombiner_results = $summaries")
#    return children
#end
#
#function recombine(recombiner::CloneRecombiner, parents::Vector{<:ModesIndividual}, state::State)
#    children = recombine(recombiner, state.individual_id_counter, parents)
#    return children
#end

end