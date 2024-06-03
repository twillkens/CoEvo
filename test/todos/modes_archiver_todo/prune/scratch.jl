
function create_modes_interaction(interaction::BasicInteraction, observers::Vector{<:Observer})
    interaction = BasicInteraction(
        interaction.id,
        interaction.environment_creator,
        interaction.species_ids,
        AllVersusAllMatchMaker(),
        observers,
    )
    return interaction
end

function get_modes_interactions(prune_species::PruneSpecies, state::State)
    interactions = get_interactions(state)
    #println("interactions: $interactions")
    interactions = filter(interaction -> prune_species.id in interaction.species_ids, interactions)
    if length(interactions) == 0
        println("interactions after: $interactions")
        println("prune_species.id: $(prune_species.id)")
        throw(ErrorException("No interactions found for species $(prune_species.id)."))
    end

    # TODO: Refactor to make generic
    interactions = map(interactions) do interaction
        observer = PhenotypeStateObserver{LinearizedFunctionGraphPhenotypeState}()
        interaction = create_modes_interaction(interaction, [observer])
        return interaction
    end
    return interactions
end



function get_modes_jobs(prune_species::PruneSpecies, state::State)
    interactions = get_modes_interactions(prune_species, state)
    job_creator = BasicJobCreator(interactions, get_n_workers(state))
    to_evaluate = get_individuals_to_evaluate(prune_species)
    
    simple_species = SimpleSpecies(prune_species.id, to_evaluate)
    other_simple_species = [
        SimpleSpecies(species.id, [
            get_previous_population(species) ; 
            [
                individual for individual in get_previous_elites(species) 
                if individual.id in get_previous_elite_ids(species)
            ]
        ])
        for species in filter(species -> species.id != prune_species.id, get_all_species(state))
    ]
    #println("length_other_individuals = $(length(first(other_simple_species).population))")
    all_simple_species = [simple_species ; other_simple_species]
    #phenotype_creators = get_phenotype_creators(state)
    #println("all_simple_species: $all_simple_species")
    #println("phenotype_creators: $phenotype_creators")
    jobs = create_jobs(
        job_creator, get_rng(state), all_simple_species, get_phenotype_creators(state)
    )
    #println("number_of_matches_$(prune_species.id) = $(length(first(jobs).matches))")
    return jobs, simple_species
end

function perform_evaluations(species::PruneSpecies, state::State)
    jobs, simple_species = get_modes_jobs(species, state)
    performer = BasicPerformer(get_n_workers(state))
    results = perform(performer, jobs)
    #println("rng_after_perform = $(get_rng(state).state)")
    outcomes = Dict(id => value for (id, value) in get_individual_outcomes(results) if id < 0)
    #println("outcomes = $outcomes")
    evaluator = ScalarFitnessEvaluator()
    evaluation = evaluate(evaluator, get_rng(state), simple_species, outcomes)
    #println("rng_after_evaluate = $(get_rng(state).state)")
    observations = [result.observation for result in results]
    return evaluation, observations
end

function validate_states(individual::PruneIndividual)
    for node_id in individual.prunable_genes
        for state in individual.states
            if node_id ∉ keys(state.node_values)
                throw(ErrorException("Hidden node ID $node_id not found in state: $state."))
            end
        end
    end
end