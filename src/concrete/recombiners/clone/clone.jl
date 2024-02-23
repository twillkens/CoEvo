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
    child.id = step!(state.individual_id_counter)
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

end