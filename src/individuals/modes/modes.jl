module Modes

export ModesIndividual, ModesIndividualCreator, create_individuals
export is_child, age_individuals

import ...Individuals: create_individuals

using Random: AbstractRNG
using StatsBase: median
using ...Abstract.States: State
using ...Counters: Counter, count!
using ...Genotypes: Genotype, get_prunable_genes, GenotypeCreator, create_genotypes
using ...Individuals: Individual, IndividualCreator
using ...Phenotypes: PhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeState
using ...Phenotypes.FunctionGraphs.Linearized: get_node_median_value
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: substitute_node_with_bias_connection

struct ModesIndividual{G <: Genotype} <: Individual
    id::Int
    parent_id::Int
    tag::Int
    genotype::G
end

struct ModesIndividualCreator <: IndividualCreator end

function create_individuals(
    ::ModesIndividualCreator, 
    rng::AbstractRNG,
    genotype_creator::GenotypeCreator, 
    n_population::Int, 
    individual_id_counter::Counter,
    gene_id_counter::Counter,
)
    ids = count!(individual_id_counter, n_population)
    genotypes = create_genotypes(genotype_creator, rng, gene_id_counter, n_population)
    individuals = [
        ModesIndividual(id, id, id, genotype) 
        for (id, genotype) in zip(ids, genotypes)
    ]
    return individuals
end

create_individuals(
    individual_creator::ModesIndividualCreator, 
    genotype_creator::GenotypeCreator,
    state::State
) = create_individuals(
    individual_creator, state.rng, genotype_creator, state.n_population, 
    state.individual_id_counter, state.gene_id_counter
)

end