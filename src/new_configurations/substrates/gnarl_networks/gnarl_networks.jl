module GnarlNetworks

export GnarlNetworkSubstrateConfiguration

import ..SubstrateConfigurations: make_genotype_creator, make_individual_creator
import ..SubstrateConfigurations: make_phenotype_creator, make_recombiner, make_mutators

using ...SubstrateConfigurations: SubstrateConfiguration
using ....Genotypes.GnarlNetworks: GnarlNetworkGenotypeCreator
using ....Mutators.GnarlNetworks: GnarlNetworkMutator
using ....Individuals.Basic: BasicIndividualCreator
using ....Recombiners.Clone: CloneRecombiner
using ...GameConfigurations: GameConfiguration
using ...SubstrateConfigurations: SubstrateConfiguration
using ....Phenotypes.Defaults: DefaultPhenotypeCreator

struct GnarlNetworkSubstrateConfiguration <: SubstrateConfiguration
    id::String
    n_population::Int
    n_children::Int
end

function GnarlNetworkSubstrateConfiguration(;
    id::String = "gnarl_networks", 
    n_population::Int = 10, 
    n_children::Int = 10, 
    kwargs...
)
    substrate = GnarlNetworkSubstrateConfiguration(id, n_population, n_children)
    return substrate
end

function make_genotype_creator(
    ::GnarlNetworkSubstrateConfiguration, game::GameConfiguration
)
    communication_dimension = game.communication_dimension
    genotype_creator = GnarlNetworkGenotypeCreator(
        n_input_nodes = 1 + communication_dimension, 
        n_output_nodes = 1 + communication_dimension
    )
    return genotype_creator
end

make_individual_creator(::GnarlNetworkSubstrateConfiguration) = BasicIndividualCreator()

make_phenotype_creator(::GnarlNetworkSubstrateConfiguration) = DefaultPhenotypeCreator()

make_recombiner(::GnarlNetworkSubstrateConfiguration) = CloneRecombiner()

make_mutators(::GnarlNetworkSubstrateConfiguration) = [GnarlNetworkMutator()]


end