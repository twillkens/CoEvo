module FiniteStateMachines

export FiniteStateMachineSubstrateConfiguration

import ..SubstrateConfigurations: make_genotype_creator, make_individual_creator
import ..SubstrateConfigurations: make_phenotype_creator, make_recombiner, make_mutators

using ...SubstrateConfigurations: SubstrateConfiguration
using ....Genotypes.FiniteStateMachines: FiniteStateMachineGenotypeCreator
using ....Mutators.FiniteStateMachines: FiniteStateMachineMutator
using ....Individuals.Basic: BasicIndividualCreator
using ....Recombiners.Clone: CloneRecombiner
using ...GameConfigurations: GameConfiguration
using ...SubstrateConfigurations: SubstrateConfiguration
using ....Phenotypes.Defaults: DefaultPhenotypeCreator

struct FiniteStateMachineSubstrateConfiguration <: SubstrateConfiguration
    id::String
    n_population::Int
    n_children::Int
end

make_genotype_creator(
    ::FiniteStateMachineSubstrateConfiguration, ::GameConfiguration
) = FiniteStateMachineGenotypeCreator()

make_individual_creator(::FiniteStateMachineSubstrateConfiguration) = BasicIndividualCreator()

make_phenotype_creator(::FiniteStateMachineSubstrateConfiguration) = DefaultPhenotypeCreator()

make_recombiner(::FiniteStateMachineSubstrateConfiguration) = CloneRecombiner()

make_mutators(::FiniteStateMachineSubstrateConfiguration) = [FiniteStateMachineMutator()]


end