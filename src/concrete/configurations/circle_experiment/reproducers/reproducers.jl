using ...Reproducers.Basic: BasicReproducer

function BasicReproducer(
    config::CircleExperimentConfiguration
)
    state = BasicReproducer(
        species_ids = PREDICTION_GAME_TOPOLOGIES[config.topology].species_ids,
        gene_id_counter = StepCounter(1, config.n_ecosystems),
        genotype_creator = SimpleFunctionGraphGenotypeCreator(
            n_inputs = 2, n_hidden = 1, n_outputs = 1, n_bias = 1
        ),
        recombiner = HorizontalGeneTransferRecombiner(transfer_probability = 0.5),
        mutator = MUTATORS[config.mutator],
        phenotype_creator = CompleteFunctionGraphPhenotypeCreator(),
        individual_id_counter = StepCounter(1, config.n_ecosystems),
        individual_creator = ModesIndividualCreator(),
        selector = SELECTORS[config.selector],
        species_creator = SPECIES_CREATORS[config.species],
        ecosystem_creator = SimpleEcosystemCreator(),
        reproduction_time = 0.0
    )
    return state
end