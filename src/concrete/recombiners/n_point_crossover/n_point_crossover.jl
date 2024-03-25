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
using ...Individuals.Dodo: DodoIndividual

# Define a struct for the N-point crossover recombiner
Base.@kwdef struct NPointCrossoverRecombiner <: Recombiner
    n_points::Int = 1 # Default number of crossover points
    use_age::Bool = false # Whether to use age in crossover
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
    child_genes1 = copy(genes1)
    child_genes2 = copy(genes2)
    for i in 1:2:length(points)
        if i+1 > length(points)
            break
        end
        start_idx, end_idx = points[i], points[i+1]
        child_genes1[start_idx:end_idx] = genes2[start_idx:end_idx]
        child_genes2[start_idx:end_idx] = genes1[start_idx:end_idx]
    end
    child_genes3 = [1 - g for g in child_genes1]
    child_genes4 = [1 - g for g in child_genes2]
    
    if length(genes1) != length(child_genes1) || 
        length(genes1) != length(child_genes2) || 
        length(genes1) != length(child_genes3) ||
        length(genes1) != length(child_genes4)
        error("Child genes must be of equal length for N-point crossover")
    end
    #return [child_genes1, child_genes2, child_genes3, child_genes4]
    return [child_genes1, child_genes2]
end


using ...Recombiners.Clone: CloneRecombiner

function create_children(
    recombiner::NPointCrossoverRecombiner, 
    mutator::Mutator, 
    phenotype_creator::PhenotypeCreator, 
    parents::Vector{<:Individual}, 
    state::State
)
    parents = [deepcopy(parent) for parent in parents]
    if length(parents) == 2
        genes1, genes2 = extract_genes(parents)
        points = generate_crossover_points(recombiner.n_points, length(genes1))
        child_genes_1, child_genes_2 = perform_crossover(genes1, genes2, points)
        parents[1].genotype = BasicVectorGenotype(child_genes_1)
        parents[2].genotype = BasicVectorGenotype(child_genes_2)
        children = recombine(CloneRecombiner(), mutator, phenotype_creator, parents, state)
    else
        error("N-point crossover only supports 1 or 2 parents")
    end
    return children
end


using StatsBase

function recombine(
    recombiner::NPointCrossoverRecombiner, 
    mutator::Mutator, 
    phenotype_creator::PhenotypeCreator,
    all_parents::Vector{I},
    state::State
) where I <: BasicIndividual
    all_children = I[]
    for _ in 1:div(length(all_parents), 2)
        parents = sample(all_parents, 2, replace=false)
        children = create_children(recombiner, mutator, phenotype_creator, parents, state)
        append!(all_children, children)
    end
    return all_children
end

end
#function recombine(
#    recombiner::NPointCrossoverRecombiner, mutator::Mutator, selection::Selection, state::State
#)
#    parents = [deepcopy(record.individual) for record in selection.records]
#    #for parent in parents
#    #    n_mutations = rand(state.rng, 1:parent.temperature)
#    #    for _ in 1:n_mutations
#    #        mutate!(mutator, parent.genotype, state)
#    #    end
#    #end
#    children = recombine(recombiner, parents, state)
#
#    for child in children
#        if recombiner.use_age
#            parent_ages = [parent.age for parent in parents]
#            max_age = maximum(parent_ages)
#            n_mutations = rand(state.rng, 1:max_age)
#            for _ in 1:n_mutations
#                mutate!(mutator, child.genotype, state)
#            end
#        else
#            mutate!(mutator, child.genotype, state)
#        end
#    end
#    return children
#end
#function recombine(
#    recombiner::NPointCrossoverRecombiner, mutator::Mutator, selection::Selection, state::State
#)
#    parents = [deepcopy(record.individual) for record in selection.records]
#    #for parent in parents
#    #    n_mutations = rand(state.rng, 1:parent.temperature)
#    #    for _ in 1:n_mutations
#    #        mutate!(mutator, parent.genotype, state)
#    #    end
#    #end
#    children = recombine(recombiner, parents, state)
#
#    for child in children
#        if recombiner.use_age
#            parent_ages = [parent.age for parent in parents]
#            max_age = maximum(parent_ages)
#            n_mutations = rand(state.rng, 1:max_age)
#            for _ in 1:n_mutations
#                mutate!(mutator, child.genotype, state)
#            end
#        else
#            mutate!(mutator, child.genotype, state)
#        end
#    end
#    return children
#end
#function recombine(
#    recombiner::NPointCrossoverRecombiner, 
#    mutator::Mutator, 
#    selections::Vector{<:Selection}, 
#    state::State
#)
#    children = [recombine(recombiner, mutator, selection, state) for selection in selections]
#    children = vcat(children...)
#    return children
#end
#
#using ...Selectors.Selections: BasicSelection
#
#function recombine(
#    recombiner::NPointCrossoverRecombiner, 
#    mutator::Mutator, 
#    all_parents::Vector,
#    state::State
#)
#    selections = [BasicSelection(parents) for parents in all_parents]
#    children = recombine(recombiner, mutator, selections, state)
#    return children
#end
#function create_child(child_genes::Vector, parents::Vector{<:DodoIndividual}, state::State)
#    id = step!(state.individual_id_counter)
#    child = DodoIndividual(
#        id = id, 
#        parent_ids = [parent.id for parent in parents],
#        age = 0,
#        temperature = 1,
#        genotype = BasicVectorGenotype(child_genes), 
#        phenotype = BasicVectorPhenotype(id, child_genes)
#    )
#    return child
#end
#
#function create_children(
#    all_child_genes::Vector{T}, parents::Vector{<:DodoIndividual}, state::State
#) where T
#    children = [create_child(child_genes, parents, state) for child_genes in all_child_genes]
#    return children
#end