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
    full_fitness::Float64
    fitness::Float64
end

function PruneIndividual(
    id::Int, 
    full_genotype::Genotype, 
    genotype::Genotype, 
    full_fitness::Float64 = 0.0,
    genes_to_check::Union{Vector{Int}, Nothing} = nothing,
    ::Type{P} = PhenotypeState
) where {P <: PhenotypeState}
    genes_to_check = genes_to_check === nothing ? get_prunable_genes(genotype) : genes_to_check
    states = P[]
    fitness = 0.0
    individual = PruneIndividual(
        id, full_genotype, genotype, genes_to_check, states, full_fitness, fitness
    )
    return individual
end

function is_fully_pruned(individual::PruneIndividual)
    fully_pruned = length(individual.genes_to_check) == 0
    return fully_pruned
end

using ...Genotypes: get_size

function modes_prune(individual::PruneIndividual{FunctionGraphGenotype, PhenotypeState})
    node_to_check = popfirst!(individual.genes_to_check)
    node_median_value = get_node_median_value(individual.states, node_to_check)
    node_median_value = isinf(node_median_value) ? 0 : node_median_value
    pruned_genotype = substitute_node_with_bias_connection(
        individual.genotype, node_to_check, node_median_value
    )
    genes_to_check = [
        gene for gene in individual.genes_to_check if gene in pruned_genotype.hidden_node_ids
    ]
    pruned_individual = PruneIndividual(
        individual.id, individual.full_genotype, pruned_genotype, individual.full_fitness,
        genes_to_check
    )
    if get_size(pruned_individual.genotype) == get_size(pruned_individual.full_genotype)
        throw(ErrorException("Pruned genotype is the same size as the full genotype."))
    end
    return individual, pruned_individual
end

end