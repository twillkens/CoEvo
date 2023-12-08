module Modes

export ModesIndividual, is_fully_pruned, modes_prune!

using StatsBase: median
using ...Genotypes: Genotype, get_prunable_genes
using ...Individuals: Individual
using ...Phenotypes: PhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: get_node_median_value
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: substitute_node_with_bias_connection

mutable struct ModesIndividual{G <: Genotype, P <: PhenotypeState} <: Individual
    id::Int
    genotype::G
    prunable_genes::Vector{Int}
    states::Vector{P}
    fitness::Float64
end

function ModesIndividual(
    id::Int, genotype::Genotype, ::Type{P} = PhenotypeState
) where {P <: PhenotypeState}
    prunable_genes = get_prunable_genes(genotype)
    states = P[]
    fitness = -Inf
    individual = ModesIndividual(id, genotype, prunable_genes, states, fitness)
    return individual
end

function is_fully_pruned(individual::ModesIndividual)
    fully_pruned = length(individual.prunable_genes) == 0
    return fully_pruned
end

function modes_prune!(
    individual::ModesIndividual{FunctionGraphGenotype, LinearizedFunctionGraphPhenotypeState}
)
    gene_to_check = popfirst!(individual.prunable_genes)
    gene_median_value = get_node_median_value(individual.states, gene_to_check)
    pruned_genotype = substitute_node_with_bias_connection(
        individual.genotype, gene_to_check, gene_median_value
    )
    pruned_individual = ModesIndividual(individual.id, pruned_genotype)
    return pruned_individual
end

end