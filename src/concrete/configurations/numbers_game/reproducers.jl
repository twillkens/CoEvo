export create_reproducers, make_species_creator, make_selector, create_reproducer

import ....Interfaces: create_reproducers, create_reproducer
using ...SpeciesCreators.HillClimber: HillClimberSpeciesCreator

function make_species_creator(config::ReproducerConfiguration)
    if config.species_type == "basic"
        species_creator = BasicSpeciesCreator(
            id = config.id,
            n_population = config.n_population,
            n_parents = config.n_parents,
            n_children = config.n_children,
            n_elites = config.n_elites,
        )
    elseif config.species_type == "redisco"
        species_creator = RediscoSpeciesCreator(
            id = config.id,
            n_population = config.n_population,
            max_archive_size = config.max_archive_size,
            max_archive_age = config.max_archive_age,
            max_mutations = config.max_mutations,
        )
    elseif config.species_type == "hillclimber"
        species_creator = HillClimberSpeciesCreator(
            id = config.id,
            n_population = config.n_population,
            max_mutations = config.max_mutations,
        )
    else
        error("Invalid species_type: $(config.species_type)")
    end
    return species_creator
end

function make_selector(config::ReproducerConfiguration)
    if config.selection_type == "fitness_proportionate"
        selector = FitnessProportionateSelector(
            n_selections = config.n_children,
            n_selection_set = 1
        ) 
    elseif config.selection_type == "tournament"
        selector = TournamentSelector(
            n_selections = config.n_children, 
            n_selection_set = 1,
            tournament_size = config.tournament_size
        )
    else
        error("Invalid selection type: $(config.selection_type)")
    end
    return selector
end

function create_reproducer(config::ReproducerConfiguration)
    bias_vector = [fill(2, config.n_dimensions ÷ 2) ; zeros(config.n_dimensions ÷ 2)]
    reproducer = BasicReproducer(
        id = config.id,
        #genotype_creator = NumbersGameVectorGenotypeCreator(
        #    length = config.n_dimensions, init_range = config.initialization_range
        #),
        genotype_creator = BiasedNumbersGameVectorGenotypeCreator(
            length = config.n_dimensions, init_range = config.initialization_range, bias = bias_vector
        ),
        phenotype_creator = NumbersGamePhenotypeCreator(
            use_delta = config.discretize_phenotypes, delta = config.discretization_delta
        ),
        individual_creator = BasicIndividualCreator(),
        species_creator = make_species_creator(config),
        selector = make_selector(config),
        recombiner = CloneRecombiner(),
        mutator = NumbersGameVectorMutator(),
    )
    return reproducer
end


function create_reproducers(config::NumbersGameExperimentConfiguration)
    reproducers = [
        create_reproducer(config.learner_reproducer_config),
        create_reproducer(config.distinguisher_reproducer_config)
    ]
    return reproducers
end