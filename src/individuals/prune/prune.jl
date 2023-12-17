module Prune

export PruneIndividual, is_fully_pruned, modes_prune

using StatsBase: median
using ...Genotypes: Genotype, get_prunable_genes
using ...Individuals: Individual
using ...Phenotypes: PhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: get_node_median_value
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: substitute_node_with_bias_connection

mutable struct PruneIndividual{G <: Genotype, P <: PhenotypeState} <: Individual
    id::Int
    full_genotype::G
    genotype::G
    genes_to_check::Vector{Int}
    states::Vector{P}
    fitness::Float64
end

function PruneIndividual(
    id::Int, full_genotype::Genotype, genotype::Genotype, ::Type{P} = PhenotypeState
) where {P <: PhenotypeState}
    genes_to_check = get_prunable_genes(genotype)
    states = P[]
    fitness = -Inf
    individual = PruneIndividual(id, full_genotype, genotype, genes_to_check, states, fitness)
    return individual
end

function is_fully_pruned(individual::PruneIndividual)
    fully_pruned = length(individual.genes_to_check) == 0
    return fully_pruned
end

function modes_prune(individual::PruneIndividual{FunctionGraphGenotype, PhenotypeState})
    node_to_check = popfirst!(individual.genes_to_check)
    node_median_value = get_node_median_value(individual.states, node_to_check)
    node_median_value = isinf(node_median_value) ? 0 : node_median_value
    pruned_genotype = substitute_node_with_bias_connection(
        individual.genotype, node_to_check, node_median_value
    )
    pruned_individual = PruneIndividual(individual.id, individual.full_genotype, pruned_genotype)
    return individual, pruned_individual
end

end