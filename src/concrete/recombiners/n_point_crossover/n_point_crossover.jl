module NPointCrossover

export NPointCrossoverRecombiner

import ....Interfaces: recombine

using Random: AbstractRNG, randperm
using ....Abstract
using ....Interfaces: step!
using ....Interfaces
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Genotypes.Vectors: BasicVectorGenotype
using ...Phenotypes.Vectors: BasicVectorPhenotype

# Define a struct for the N-point crossover recombiner
Base.@kwdef struct NPointCrossoverRecombiner <: Recombiner
    n_points::Int = 3 # Default number of crossover points
end

function validate_parents(parents::Vector{<:Individual})
    if length(parents) != 2
        error("NPointCrossover requires exactly two parents")
    end
end

function extract_genes(parents::Vector{<:Individual})
    genes1 = parents[1].genotype.genes
    genes2 = parents[2].genotype.genes
    length(genes1) == length(genes2) || error("Parent genes must be of equal length for N-point crossover")
    return genes1, genes2
end

function generate_crossover_points(n_points::Int, gene_length::Int)
    points = sort(randperm(gene_length - 1)[1:n_points])
    push!(points, gene_length) # Ensure the full range is covered
    return points
end

function perform_crossover(genes1::Vector, genes2::Vector, points::Vector{Int})
    child_genes = copy(genes1)
    for i in 1:2:length(points)
        if i+1 > length(points)
            break
        end
        start_idx, end_idx = points[i], points[i+1]
        child_genes[start_idx:end_idx] = genes2[start_idx:end_idx]
    end
    return child_genes
end

function create_child(child_genes::Vector, parents::Vector{<:Individual}, state::State)
    child = deepcopy(parents[1]) # Copy to inherit other properties
    child.id = step!(state.individual_id_counter)
    child.genotype = BasicVectorGenotype(child_genes)
    child.phenotype = BasicVectorPhenotype(child.id, child_genes)
    child.parent_id = parents[1].id
    return child
end
using ...Individuals.Dodo: DodoIndividual

function create_child(child_genes::Vector, parents::Vector{<:DodoIndividual}, state::State)
    child = deepcopy(parents[1]) # Copy to inherit other properties
    child.id = step!(state.individual_id_counter)
    child.genotype = BasicVectorGenotype(child_genes)
    child.phenotype = BasicVectorPhenotype(child.id, child_genes)
    child.parent_ids = [parent.id for parent in parents]
    return child
end

function recombine(
    recombiner::NPointCrossoverRecombiner, parents::Vector{<:Individual}, state::State
)
    validate_parents(parents)
    genes1, genes2 = extract_genes(parents)
    points = generate_crossover_points(recombiner.n_points, length(genes1))
    child_genes = perform_crossover(genes1, genes2, points)
    create_child(child_genes, parents, state)
end

function recombine(
    recombiner::NPointCrossoverRecombiner, selection::Selection, state::State
)
    parents = [record.individual for record in selection.records]
    return recombine(recombiner, parents, state)
end

function recombine(
    recombiner::NPointCrossoverRecombiner, selections::Vector{<:Selection}, state::State
)
    children = [recombine(recombiner, selection, state) for selection in selections]
    return children
end


function recombine(
    recombiner::NPointCrossoverRecombiner, parents::Vector{<:Individual}, state::State
)
    validate_parents(parents)
    genes1, genes2 = extract_genes(parents)
    points = generate_crossover_points(recombiner.n_points, length(genes1))
    child_genes = perform_crossover(genes1, genes2, points)
    create_child(child_genes, parents, state)
end

function recombine(
    recombiner::NPointCrossoverRecombiner, mutator::Mutator, selection::Selection, state::State
)
    parents = [deepcopy(record.individual) for record in selection.records]
    for parent in parents
        n_mutations = rand(state.rng, 1:parent.temperature)
        for _ in 1:n_mutations
            mutate!(mutator, parent, state)
        end
    end
    return recombine(recombiner, parents, state)
end

function recombine(
    recombiner::NPointCrossoverRecombiner, 
    mutator::Mutator, 
    selections::Vector{<:Selection}, 
    state::State
)
    children = [recombine(recombiner, mutator, selection, state) for selection in selections]
    return children
end

using ...Selectors.Selections: BasicSelection

function recombine(
    recombiner::NPointCrossoverRecombiner, 
    mutator::Mutator, 
    all_parents::Vector{Vector{<:Individual}},
    state::State
)
    selections = [BasicSelection(parents) for parents in all_parents]
    children = recombine(recombiner, mutator, selections, state)
    return children
end

end