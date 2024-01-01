export make_species_creators, make_ecosystem_creator

import ...ExperimentConfigurations: make_ecosystem_creator

using ...SubstrateConfigurations: get_n_population, get_n_children, make_individual_creator
using ...SubstrateConfigurations: make_genotype_creator, make_phenotype_creator
using ...SubstrateConfigurations: make_recombiner, make_mutators
using ...TopologyConfigurations.Basic: BasicTopologyConfiguration
using ...TopologyConfigurations.Modes: ModesTopologyConfiguration
using ....SpeciesCreators.Basic: BasicSpeciesCreator
using ....Modes: ModesSpeciesCreator
using ...ReproductionConfigurations: make_evaluator, make_replacer, make_selector


function make_species_creators(
    topology::BasicTopologyConfiguration, 
    substrate::SubstrateConfiguration, 
    reproducer::ReproductionConfiguration, 
    game::GameConfiguration
)
    species_creators = [
        BasicSpeciesCreator(
            id = species_id,
            n_population = get_n_population(substrate),
            n_children = get_n_children(substrate),
            genotype_creator = make_genotype_creator(substrate, game),
            individual_creator = make_individual_creator(substrate),
            phenotype_creator = make_phenotype_creator(substrate),
            evaluator = make_evaluator(reproducer),
            replacer = make_replacer(reproducer),
            selector = make_selector(reproducer),
            recombiner = make_recombiner(substrate),
            mutators = make_mutators(substrate),
        ) 
        for species_id in topology.species_ids
    ]
    return species_creators
end

function make_species_creators(
    topology::ModesTopologyConfiguration, 
    substrate::SubstrateConfiguration, 
    reproducer::ReproductionConfiguration, 
    game::GameConfiguration
)
    species_creators = [
        ModesSpeciesCreator(
            id = species_id,
            n_population = get_n_population(substrate),
            n_children = get_n_children(substrate),
            genotype_creator = make_genotype_creator(substrate, game),
            phenotype_creator = make_phenotype_creator(substrate),
            evaluator = make_evaluator(reproducer),
            replacer = make_replacer(reproducer),
            selector = make_selector(reproducer),
            recombiner = make_recombiner(substrate),
            mutators = make_mutators(substrate),
            modes_interval = topology.modes_interval,
            n_elites = topology.n_elites,
        ) 
        for species_id in topology.species_ids
    ]
    return species_creators
end

function make_species_creators(config::PredictionGameExperimentConfiguration)
    species_creators = make_species_creators(
        config.topology, 
        config.substrate, 
        config.reproduction, 
        config.game
    )
    return species_creators
end

using ....Ecosystems.Simple: SimpleEcosystemCreator

function make_ecosystem_creator(config::PredictionGameExperimentConfiguration,)
    ecosystem_creator = SimpleEcosystemCreator(
        id = config.id,
        species_creators = make_species_creators(config)
    )
    return ecosystem_creator
end