module Clone

export CloneRecombiner

import ....Interfaces: recombine

using Random: AbstractRNG
using ....Abstract
using ....Interfaces
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Individuals.Dodo: DodoIndividual

Base.@kwdef struct CloneRecombiner <: Recombiner end

function recombine(
    ::CloneRecombiner, 
    phenotype_creator::PhenotypeCreator, 
    individual::DodoIndividual, 
    state::State; 
    do_copy::Bool=true
)
    child = do_copy ? deepcopy(individual) : individual
    child.id = step!(state.individual_id_counter)
    child.parent_id = individual.id
    child.phenotype.id = child.id
    return child
end

#function recombine(recombiner::CloneRecombiner, parents::Vector{<:Individual}, state::State)
#    children = [recombine(recombiner, parent, state) for parent in parents]
#    return children
#end
#
#function recombine(recombiner::CloneRecombiner, selections::Vector{<:Selection}, state::State)
#    if any([length(selection.records) != 1 for selection in selections])
#        error("CloneRecombiner requires exactly one parent per selection")
#    end
#    parents = [first(selection.records).individual for selection in selections]
#    children = recombine(recombiner, parents, state)
#    return children
#end

function recombine(
    recombiner::CloneRecombiner, mutator::Mutator, selection::Selection, state::State
)
    if length(selection.records) != 1
        error("CloneRecombiner requires exactly one parent per selection")
    end
    parent = deepcopy(first(selection.records).individual)
    n_mutations = rand(state.rng, 1:parent.temperature)
    for _ in 1:n_mutations
        mutate!(mutator, parent.genotype, state)
    end
    child = recombine(recombiner, parent, state; do_copy = false)
    return child
end

function recombine(
    recombiner::CloneRecombiner, 
    mutator::Mutator, 
    selections::Vector{<:Selection}, 
    state::State
)
    children = [recombine(recombiner, mutator, selection, state) for selection in selections]
    return children
end

end