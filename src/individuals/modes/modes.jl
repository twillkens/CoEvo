module Modes

export ModesIndividual, ModesIndividualCreator, create_individuals
export is_child, age_individuals

import ...Individuals: create_individuals

using Random: AbstractRNG
using StatsBase: median
using ...Abstract.States: State
using ...Counters: Counter
using ...Genotypes: Genotype, get_prunable_genes, GenotypeCreator, create_genotypes
using ...Individuals: Individual, IndividualCreator
using ...Phenotypes: PhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: get_node_median_value
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: substitute_node_with_bias_connection

struct ModesIndividual{G <: Genotype}
    id::Int
    parent_id::Int
    tag::Int
    age::Int
    genotype::G
end

struct ModesIndividualCreator <: IndividualCreator end

function create_individuals(
    ::ModesIndividualCreator, 
    genotype_creator::GenotypeCreator, 
    n_population::Int, 
    state::State
)
    individual_id_counter = get_individual_id_counter(state)
    ids = count!(individual_id_counter, n_population)
    genotypes = create_genotypes(genotype_creator, n_population, state)
    individuals = [
        ModesIndividual(id, id, tag, 0, genotype) 
        for (tag, (id, genotype)) in enumerate(zip(ids, genotypes))
    ]
    return individuals
end

function is_child(individual::ModesIndividual)
    is_child = individual.tag == 0
    return is_child
end

function age_individuals(individuals::Vector{<:ModesIndividual}) 
    individuals = [
        ModesIndividual(
            individual.id, 
            individual.parent_id,
            individual.tag, 
            individual.age + 1,
            individual.genotype,
        ) 
        for individual in individuals
    ]
    return individuals
end

end