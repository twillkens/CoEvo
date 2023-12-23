export get_n_population, get_n_children, make_individual_creator, make_phenotype_creator
export make_recombiner, make_mutators, make_genotype_creator

using ..GameConfigurations: GameConfiguration

get_n_population(substrate::SubstrateConfiguration) = substrate.n_population

get_n_children(substrate::SubstrateConfiguration) = substrate.n_children

make_genotype_creator(substrate::SubstrateConfiguration, game::GameConfiguration) = throw(
    ErrorException("make_genotype_creator not implemented for substrate of type $(typeof(substrate))")
)

make_individual_creator(substrate::SubstrateConfiguration) = throw(
    ErrorException("make_individual_creator not implemented for substrate of type $(typeof(substrate))")
)

make_phenotype_creator(substrate::SubstrateConfiguration) = throw(
    ErrorException("make_phenotype_creator not implemented for substrate of type $(typeof(substrate))")
)

make_recombiner(substrate::SubstrateConfiguration) = throw(
    ErrorException("make_recombiner not implemented for substrate of type $(typeof(substrate))")
)

make_mutators(substrate::SubstrateConfiguration) = throw(
    ErrorException("make_mutators not implemented for substrate of type $(typeof(substrate))")
)