export PruneIndividual, is_fully_pruned, modes_prune, print_prune_summaries
export print_full_summaries

using StatsBase: median
using ....Abstract
using ....Interfaces
using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: get_node_median_value
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: substitute_node_with_bias_connection

mutable struct PruneIndividual{I <: Individual, G <: Genotype, P <: PhenotypeState} <: Individual
    id::Int
    current_genotype::G
    current_fitness::Float64
    current_node_medians::Vector{Float32}
    candidate_genotype::G
    genes_to_check::Vector{Int}
end

function PruneIndividual(individual::Individual, evaluation::Evaluation)
    current_fitness = first(filter(x -> x.id == individual.id, evaluation.individuals)).fitness
    PruneIndividual(
        id = individual.id,
        current_genotype = individual.genotype,
        current_fitness = current_fitness,
    )


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

is_fully_pruned(individual::PruneIndividual)= length(individual.genes_to_check) == 0

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

function print_prune_summaries(species_id::String, new_pruned::Vector{<:PruneIndividual})
    ids = [individual.id for individual in new_pruned]
    sizes = [get_size(individual.genotype) for individual in new_pruned]
    fitnesses = [individual.fitness for individual in new_pruned]
    summaries = [
        (id, size, round(fitness; digits = 3)) 
        for (id, size, fitness) in zip(ids, sizes, fitnesses)
    ]
    sort!(summaries, by = x -> x[3]; rev = true)
    println("$(species_id)_prune = ", summaries)
end

function print_full_summaries(species_id::String, new_modes_pruned::Vector{<:PruneIndividual})
    ids = [individual.id for individual in new_modes_pruned]
    sizes = [get_size(minimize(individual.full_genotype)) for individual in new_modes_pruned]
    fitnesses = [round(individual.full_fitness, digits = 3) for individual in new_modes_pruned]
    summaries = [
        (id, size, fitness) 
        for (id, size, fitness) in zip(ids, sizes, fitnesses)
    ]
    println("$(species_id)_full = $summaries")
end