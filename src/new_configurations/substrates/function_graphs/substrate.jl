export FunctionGraphSubstrateConfiguration

import ...SubstrateConfigurations: make_genotype_creator, make_individual_creator
import ...SubstrateConfigurations: make_phenotype_creator, make_recombiner, make_mutators

using ....Genotypes.FunctionGraphs: FunctionGraphGenotypeCreator
using ....Individuals.Basic: BasicIndividualCreator
using ....Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeCreator
using ....Recombiners.Clone: CloneRecombiner
using ...GameConfigurations.ContinuousPredictionGame: ContinuousPredictionGameConfiguration
using ...SubstrateConfigurations: SubstrateConfiguration

struct FunctionGraphSubstrateConfiguration <: SubstrateConfiguration
    id::String
    n_population::Int
    n_children::Int
    n_nodes_per_output::Int
    function_set::String
    mutation::String
    noise_std::String
end

function FunctionGraphSubstrateConfiguration(;
    id::String = "function_graphs",
    n_population::Int = 10, 
    n_children::Int = 10, 
    n_nodes_per_output::Int = 1, 
    function_set::String = "all",
    mutation::String = "equal_volatile",
    noise_std::String = "moderate",
    kwargs...
)
    substrate = FunctionGraphSubstrateConfiguration(
        id, n_population, n_children, n_nodes_per_output, function_set, mutation, noise_std
    )
    return substrate
end

function make_genotype_creator(
    substrate::FunctionGraphSubstrateConfiguration, 
    game::ContinuousPredictionGameConfiguration
)
    n_nodes_per_output = substrate.n_nodes_per_output
    communication_dimension = game.communication_dimension
    genotype_creator = FunctionGraphGenotypeCreator(
        n_inputs = 2 + communication_dimension, 
        n_bias = 1,
        n_outputs = 1 + communication_dimension,
        n_nodes_per_output = n_nodes_per_output,
    )
    return genotype_creator
end

make_individual_creator(::FunctionGraphSubstrateConfiguration) = BasicIndividualCreator()

make_phenotype_creator(
    ::FunctionGraphSubstrateConfiguration
) = LinearizedFunctionGraphPhenotypeCreator()

make_recombiner(::FunctionGraphSubstrateConfiguration) = CloneRecombiner()