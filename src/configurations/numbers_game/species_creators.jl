
function make_reproducer_types(configuration::NumbersGameConfiguration)
    reproduction_method = configuration.reproduction_method
    if reproduction_method == "roulette"
        evaluator = ScalarFitnessEvaluator()
        selector = FitnessProportionateSelector(n_parents = configuration.n_population)
    elseif reproduction_method == "disco"
        evaluator = NSGAIIEvaluator(
            maximize = true, perform_disco = true, max_clusters = configuration.max_clusters,
            scalar_fitness_evaluator = ScalarFitnessEvaluator(),
        )
        selector = TournamentSelector(
            n_parents = configuration.n_population, 
            tournament_size = configuration.tournament_size
        )
    else
        throw(ArgumentError("Unrecognized reproduction method: $reproduction_method"))
    end
    return evaluator, selector
end

function make_species_creators(configuration::NumbersGameConfiguration)
    species_ids = ["A", "B"]
    evaluator, selector = make_reproducer_types(configuration)
    species_creators = [
        BasicSpeciesCreator(
            id = species_id,
            n_population = configuration.n_population,
            n_children = configuration.n_population,
            genotype_creator = BasicVectorGenotypeCreator(),
            individual_creator = BasicIndividualCreator(),
            phenotype_creator = DefaultPhenotypeCreator(),
            evaluator = evaluator,
            replacer = TruncationReplacer(n_truncate = configuration.n_population),
            selector = selector,
            recombiner = CloneRecombiner(),
            mutators = [BasicVectorMutator(
                noise_standard_deviation = configuration.noise_standard_deviation
            )],
        ) 
        for species_id in species_ids
    ]
    return species_creators
end