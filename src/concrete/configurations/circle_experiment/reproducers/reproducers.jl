using ...Reproducers.Basic: BasicReproducer

using ...Counters.Step
using ...Genotypes.FunctionGraphs: FunctionGraphGenotypeCreator
using ...Phenotypes.FunctionGraphs: FunctionGraphPhenotypeCreator
using ...Individuals.Modes
using ...Ecosystems.Simple
using ...Recombiners.HorizontalGeneTransfer

import ....Interfaces: create_reproducer

include("function_sets.jl")

include("mutators.jl")

include("selectors.jl")

include("species_creators.jl")

function create_reproducer(config::CircleExperimentConfiguration)
    species_creator = SPECIES_CREATORS[config.species]
    state = BasicReproducer(
        species_ids = PREDICTION_GAME_TOPOLOGIES[config.topology].species_ids,
        gene_id_counter = StepCounter(config.id, config.n_ecosystems),
        genotype_creator = FunctionGraphGenotypeCreator(
            n_inputs = 2, n_hidden = 1, n_outputs = 1, n_bias = 1
        ),
        recombiner = HorizontalGeneTransferRecombiner(transfer_probability = 0.5),
        mutator = MUTATORS[config.mutator],
        phenotype_creator = FunctionGraphPhenotypeCreator(),
        individual_id_counter = StepCounter(config.id, config.n_ecosystems),
        individual_creator = ModesIndividualCreator(),
        selector = create_selector(config, species_creator),
        species_creator = species_creator,
        ecosystem_creator = SimpleEcosystemCreator(),
    )
    return state
end