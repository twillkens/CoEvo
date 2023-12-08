mutable struct ModesIndividual{G <: Genotype} <: Individual
    id::Int
    genotype::G
    genes_to_check::Vector{Int}
    observations::Vector{<:Observation}
    fitness::Float64
end

function ModesIndividual(id::Int, genotype::Genotype)
    genes_to_check = get_genes_to_check(genotype)
    observations = Observation[]
    fitness = -Inf
    individual = ModesIndividual(id, genotype, genes_to_check, observations, fitness)
    return individual
end

function is_fully_pruned(individual::ModesIndividual)
    return length(individual.genes_to_check) == 0
end

function get_maximum_complexity(genotypes::Vector{<:Genotype})
    maximum_complexity = maximum(get_size(genotype) for genotype in genotypes)
    return maximum_complexity
end

function get_maximum_complexity(individuals::Vector{<:Individual})
    return get_maximum_complexity([individual.genotype for individual in individuals])
end

function modes_prune!(individual::ModesIndividual)
    gene_median_dict = get_gene_median_dict(individual)
    gene_to_check = popfirst!(individual.genes_to_check)
    gene_median_value = gene_median_dict[gene_to_check]
    pruned_genotype = modes_prune(
        individual.genotype, gene_to_check, gene_median_value
    )
    pruned_individual = ModesIndividual(individual.id, pruned_genotype)
    return pruned_individual
end

function get_gene_median_dict(individual::ModesIndividual)
    gene_median_dict = get_gene_median_dict(individual.observations)
    return gene_median_dict
end