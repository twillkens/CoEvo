module Clone

export CloneRecombiner

import ....Interfaces: recombine

using Random: AbstractRNG
using ....Abstract
using ....Interfaces
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Individuals.Dodo: DodoIndividual

Base.@kwdef struct CloneRecombiner <: Recombiner 
    n_selection_sets::Int = 1
end

using ...Selectors.Selections: BasicSelection

function recombine(
    ::CloneRecombiner, 
    mutator::Mutator, 
    phenotype_creator::PhenotypeCreator, 
    parent::Individual, 
    state::State
)
    id = step!(state.individual_id_counter)
    genotype = mutate(mutator, parent.genotype, state)
    I = typeof(parent)
    child = DodoIndividual(id, parent.id, genotype, phenotype_creator)
    return child
end

function recombine(
    recombiner::CloneRecombiner, 
    mutator::Mutator, 
    phenotype_creator::PhenotypeCreator,
    parents::Vector{<:Individual},
    state::State
)
    children = [
        recombine(recombiner, mutator, phenotype_creator, parent, state) for parent in parents
    ]
    return children
end

function recombine(
    recombiner::CloneRecombiner, 
    mutator::Mutator, 
    phenotype_creator::PhenotypeCreator, 
    selection::BasicSelection, 
    state::State
)
    if length(selection.records) != 1
        error("CloneRecombiner requires exactly one parent per selection")
    end
    parent = first(selection.records).individual
    child = recombine(recombiner, mutator, phenotype_creator, parent, state)
    return child
end

function recombine(
    recombiner::CloneRecombiner, 
    mutator::Mutator, 
    phenotype_creator::PhenotypeCreator,
    selections::Vector{<:Selection}, 
    state::State
)
    children = [
        recombine(recombiner, mutator, phenotype_creator, selection, state) 
        for selection in selections
    ]
    return children
end

end