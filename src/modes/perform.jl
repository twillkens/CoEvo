import ...Species: get_individuals_to_evaluate, get_individuals_to_perform

using ...Results: get_individual_outcomes, get_observations
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluator

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
    filter!(interaction -> prune_species.id in interaction.species_ids, interactions)

    # TODO: Refactor to make generic
    interactions = map(interactions) do interaction
        observer = PhenotypeStateObserver{LinearizedFunctionGraphPhenotypeState}()
        interaction = create_modes_interaction(interaction, [observer])
        return interaction
    end
    return interactions
end


struct SimpleSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
end

get_individuals(species::SimpleSpecies) = species.population

get_individuals_to_evaluate(species::SimpleSpecies) = species.population    
get_individuals_to_perform(species::SimpleSpecies) = species.population


function get_modes_jobs(prune_species::PruneSpecies, state::State)
    interactions = get_modes_interactions(prune_species, state)
    job_creator = BasicJobCreator(interactions, get_n_workers(state))
    to_evaluate = get_individuals_to_evaluate(prune_species)
    simple_species = SimpleSpecies(prune_species.id, to_evaluate)
    other_simple_species = [
        SimpleSpecies(species.id, [
            species.previous_population ; 
            species.adaptive_archive.individuals ; 
            species.elites_archive.individuals
        ])
        for species in filter(species -> species.id != prune_species.id, get_all_species(state))
    ]
    println("length_other_individuals = $(length(first(other_simple_species).population))")
    all_simple_species = [simple_species ; other_simple_species]
    #phenotype_creators = get_phenotype_creators(state)
    #println("all_simple_species: $all_simple_species")
    #println("phenotype_creators: $phenotype_creators")
    jobs = create_jobs(
        job_creator, get_rng(state), all_simple_species, get_phenotype_creators(state)
    )
    return jobs, simple_species
end

function perform_evaluations(species::PruneSpecies, state::State)
    jobs, simple_species = get_modes_jobs(species, state)
    performer = BasicPerformer(get_n_workers(state))
    results = perform(performer, jobs)
    outcomes = Dict(id => value for (id, value) in get_individual_outcomes(results) if id < 0)
    evaluator = ScalarFitnessEvaluator()
    evaluation = evaluate(evaluator, get_rng(state), simple_species, outcomes)
    observations = get_observations(results)
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

function update_individual(
    individual::PruneIndividual, evaluation::Evaluation, observations::Vector{<:Observation}
)
    observations = get_observations(observations, individual.id)
    states = vcat([observation.states for observation in observations]...)
    individual.fitness = get_scaled_fitness(evaluation, individual.id)
    individual.states = states
end

function perform_simulation!(species::PruneSpecies, state::State)
    evaluation, observations = perform_evaluations(species, state)
    for individual in get_individuals_to_evaluate(species)
        update_individual(individual, evaluation, observations)
    end
end

function get_control_prune_species(species::ModesSpecies)
    individuals = [
        PruneIndividual(individual.id, minimize(individual.genotype)) 
        for individual in species.to_prune
    ]
    species = PruneSpecies(species.id, individuals)
    return species
end

function validate_candidates(species, candidates)
    ids = [individual.id for individual in candidates]
    if length(ids) != length(unique(ids))
        throw(ErrorException("Species $(species.id) has $(length(ids)) individuals but" * 
        " $(length(unique(ids))) unique ids."))
    end
end

function update_candidates(species::PruneSpecies{I}) where {I <: PruneIndividual}
    if is_fully_pruned(species)
        return species
    end
    currents = I[]
    candidates = I[]
    for individual in species.currents
        current, candidate = modes_prune(individual)
        push!(currents, current)
        push!(candidates, candidate)
    end
    validate_candidates(species, candidates)
    #println("---update_candidates")
    #println("length currents: $(length(currents))")
    #println("length candidates: $(length(candidates))")
    next_species = PruneSpecies(species.id, currents, candidates, species.pruned)
    return next_species
end

function update_currents(species::PruneSpecies{I}) where {I <: Individual}
    if is_fully_pruned(species)
        return species
    end
    currents = I[]
    pruned = copy(species.pruned)
    for (current, candidate) in zip(species.currents, species.candidates)
        candidate_is_no_worse = candidate.fitness >= current.fitness
        to_keep = candidate_is_no_worse ? candidate : current
        to_push = is_fully_pruned(to_keep) ? pruned : currents
        push!(to_push, to_keep)
    end
    #println("---update_currents")
    #println("length currents: $(length(currents))")
    #println("length pruned: $(length(pruned))")
    new_species = PruneSpecies(species.id, currents, I[], pruned)
    return new_species
end

function perform_modes(species::ModesSpecies, state::State)
    prune_species = PruneSpecies(species)
    length_start = length(prune_species.currents) + length(prune_species.pruned)
    #println("prune_species: $prune_species")
    #println("--------$(species.id)------------")
    #println("length pruned before = $(length(prune_species.pruned))")

    if first(get_interactions(state)).id == "Control-A-B" || is_fully_pruned(prune_species)
        pruned_individuals = prune_species.pruned
        ids = [individual.id for individual in pruned_individuals]
        sizes = [get_size(individual.genotype) for individual in pruned_individuals]
        fitnesses = [individual.fitness for individual in pruned_individuals]
        summaries = [(id, size, round(fitness; digits = 3)) for (id, size, fitness) in zip(ids, sizes, fitnesses)]
        println("$(species.id) -- pruned individuals: ", summaries)
        return prune_species.pruned
    end
    perform_simulation!(prune_species, state)
    while !is_fully_pruned(prune_species)
        prune_species = update_candidates(prune_species)
        #n_currents = length(prune_species.currents)
        #n_candidates = length(prune_species.candidates)
        #n_pruned = length(prune_species.pruned)
        #println("after update_candidates, currents = $n_currents, candidates = $n_candidates, pruned = $n_pruned")
        perform_simulation!(prune_species, state)
        prune_species = update_currents(prune_species)
        #n_currents = length(prune_species.currents)
        #n_candidates = length(prune_species.candidates)
        #n_pruned = length(prune_species.pruned)
        #println("after update_currents, currents = $n_currents, candidates = $n_candidates, pruned = $n_pruned")
    end
    # n_currents = length(prune_species.currents)
    # n_candidates = length(prune_species.candidates)
    # n_pruned = length(prune_species.pruned)
    #println("currents = $n_currents, candidates = $n_candidates, pruned = $n_pruned")
    pruned_individuals = prune_species.pruned
    #println("length pruned after = $(length(pruned_individuals))")
    if length(pruned_individuals) == 0
        println("species =  $prune_species")
        throw(ErrorException("No individuals were pruned."))
    end
    if length(pruned_individuals) != length_start
        println("prune_species = $prune_species")
        println("pruned_individuals_after: $pruned_individuals")
        throw(ErrorException("length pruned_individuals != length_start"))
    end
    ids = [individual.id for individual in pruned_individuals]
    sizes = [get_size(individual.genotype) for individual in pruned_individuals]
    fitnesses = [individual.fitness for individual in pruned_individuals]
    summaries = [
        (id, size, round(fitness; digits = 3)) 
        for (id, size, fitness) in zip(ids, sizes, fitnesses)
    ]
    sort!(summaries, by = x -> x[3]; rev = true)
    println("$(species.id) -- pruned individuals: ", summaries)
    return pruned_individuals
end
