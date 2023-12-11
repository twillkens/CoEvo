export make_species_creators

using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...SpeciesCreators.AdaptiveArchive: AdaptiveArchiveSpeciesCreator


function make_species_creators(
    topology::BasicTopology, 
    substrate::Substrate, 
    reproducer::Reproducer, 
    game::GameConfiguration
)
    species_ids = get_species_ids(topology)
    species_creators = [
        BasicSpeciesCreator(
            id = species_id,
            n_population = get_n_population(substrate),
            n_children = get_n_children(substrate),
            genotype_creator = make_genotype_creator(substrate, game),
            individual_creator = make_individual_creator(substrate),
            phenotype_creator = make_phenotype_creator(substrate),
            evaluator = make_evaluator(reproducer, topology),
            replacer = make_replacer(reproducer),
            selector = make_selector(reproducer),
            recombiner = make_recombiner(substrate),
            mutators = make_mutators(substrate),
        ) 
        for species_id in species_ids
    ]
    return species_creators
end

function make_species_creators(
    topology::AdaptiveArchiveTopology, 
    substrate::Substrate, 
    reproducer::Reproducer, 
    game::GameConfiguration
)
    basic_topology = topology.basic_topology
    basic_species_creators = make_species_creators(basic_topology, substrate, reproducer, game)
    species_creators = [
        AdaptiveArchiveSpeciesCreator(
            id = basic_species_creator.id,
            max_archive_size = topology.max_archive_size,
            n_sample = topology.n_sample,
            basic_species_creator = basic_species_creator,
            evaluator = AdaptiveArchiveEvaluator(
                non_archive_evaluator = ScalarFitnessEvaluator(),
                full_evaluator = basic_species_creator.evaluator,
            ),
        )
        for basic_species_creator in basic_species_creators
    ]
    return species_creators
end