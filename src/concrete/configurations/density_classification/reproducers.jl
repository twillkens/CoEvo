export create_reproducers, make_species_creator, make_selector, create_reproducer

import ....Interfaces: create_reproducers, create_reproducer
using ...SpeciesCreators.HillClimber: HillClimberSpeciesCreator
using ...SpeciesCreators.Dodo: DodoSpeciesCreator
using ...SpeciesCreators.DodoLearner: DodoLearnerSpeciesCreator
using ...SpeciesCreators.DodoTest: DodoTestSpeciesCreator
using ...Selectors.UniformRandom: UniformRandomSelector
using ...Selectors.Identity: IdentitySelector
using ...Phenotypes.Vectors: CloneVectorPhenotypeCreator
using ...Recombiners.NPointCrossover: NPointCrossoverRecombiner
using ...Individuals.Dodo: DodoIndividualCreator

function make_species_creator(config::ReproducerConfiguration)
    if config.species_type == "basic"
        species_creator = BasicSpeciesCreator(
            id = config.id,
            n_population = config.n_population,
            n_parents = config.n_parents,
            n_children = config.n_children,
            n_elites = config.n_elites,
        )
    elseif config.species_type == "dodo"
        species_creator = DodoSpeciesCreator(
            id = config.id,
            n_population = config.n_population,
            max_mutations = config.max_mutations,
        )
    elseif config.species_type == "dodo_learner"
        species_creator = DodoLearnerSpeciesCreator(
            id = config.id,
            n_parents = config.n_parents,
        )
    elseif config.species_type == "dodo_test"
        species_creator = DodoTestSpeciesCreator(
            id = config.id,
            n_explorers = config.n_parents,
        )
    else
        error("Invalid species_type: $(config.species_type)")
    end
    return species_creator
end

function make_selector(config::ReproducerConfiguration)
    n_selection_set = config.recombiner == "clone" ? 1 : 2
    if config.selection_type == "fitness_proportionate"
        selector = FitnessProportionateSelector(
            n_selections = config.n_children,
            n_selection_set = n_selection_set
        ) 
    elseif config.selection_type == "tournament"
        selector = TournamentSelector(
            n_selections = config.n_children, 
            n_selection_set = n_selection_set,
            tournament_size = config.tournament_size
        )
    elseif config.selection_type == "uniform_random"
        selector = UniformRandomSelector(
            n_selections = config.n_children,
            n_selection_set = n_selection_set
        )
    elseif config.selection_type == "identity"
        selector = IdentitySelector()
    else
        error("Invalid selection type: $(config.selection_type)")
    end
    return selector
end

function make_genotype_creator(config::ReproducerConfiguration)
    if config.id == "R"
        genotype_creator = RuleCreator(length = config.n_dimensions)
    elseif config.id == "IC"
        genotype_creator = InitialConditionCreator(length = config.n_dimensions)
    else
        error("Invalid id: $(config.id)")
    end
    return genotype_creator
end

function make_recombiner(config::ReproducerConfiguration)
    if config.recombiner == "clone"
        #recombiner = CloneRecombiner()
        recombiner = NPointCrossoverRecombiner(n_points = 1)
    elseif config.recombiner == "n_point_crossover"
        recombiner = NPointCrossoverRecombiner(n_points = 1)
    else
        error("Invalid recombiner: $(config.recombiner)")
    end
    return recombiner
end

function create_reproducer(config::ReproducerConfiguration)
    reproducer = BasicReproducer(
        id = config.id,
        genotype_creator = make_genotype_creator(config),
        phenotype_creator = CloneVectorPhenotypeCreator(),
        #individual_creator = BasicIndividualCreator(),
        individual_creator = DodoIndividualCreator(),
        species_creator = make_species_creator(config),
        selector = make_selector(config),
        recombiner = make_recombiner(config),
        mutator = PerBitMutator(config.flip_chance),
    )
    return reproducer
end


function create_reproducers(config::DensityClassificationExperimentConfiguration)
	println("HUH=",config.learner_reproducer_config )
    reproducers = [
        create_reproducer(config.learner_reproducer_config),
        create_reproducer(config.distinguisher_reproducer_config)
    ]
    return reproducers
end
