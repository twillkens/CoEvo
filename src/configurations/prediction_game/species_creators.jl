export make_species_creators

function make_species_creators(
    topology::Topology, substrate::Substrate, reproducer::Reproducer, game::GameConfiguration
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
            evaluator = make_evaluator(reproducer),
            replacer = make_replacer(reproducer),
            selector = make_selector(reproducer),
            recombiner = make_recombiner(substrate),
            mutators = make_mutators(substrate),
        ) 
        for species_id in species_ids
    ]
    return species_creators
end