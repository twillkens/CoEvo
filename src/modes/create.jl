using ..Individuals.Modes: age_individuals
using ..Individuals.Prune: print_full_summaries, print_prune_summaries
using ..Counters: Counter, count!
using ..Abstract.States: get_generation
using ..Genotypes: get_size
using ..Abstract.States: get_rng, get_individual_id_counter, get_gene_id_counter
using ..Abstract.States: get_evaluation, find_by_id
using ..Species.Modes: add_elites_to_archive, ModesSpecies, ModesCheckpointState, get_pruned
using ..Species.Modes: get_pruned_fitnesses
using ..Evaluators: Evaluation, get_records


Base.@kwdef struct ModesSpeciesCreator{
    G <: GenotypeCreator,
    P <: PhenotypeCreator,
    E <: Evaluator,
    RP <: Replacer,
    S <: Selector,
    RC <: Recombiner,
    M <: Mutator,
} <: SpeciesCreator
    id::String
    n_population::Int
    n_children::Int
    n_elites::Int
    genotype_creator::G
    phenotype_creator::P
    evaluator::E
    replacer::RP
    selector::S
    recombiner::RC
    mutators::Vector{M}
    modes_interval::Int
end

function create_species(
    species_creator::ModesSpeciesCreator, 
    rng::AbstractRNG, 
    individual_id_counter::Counter, 
    gene_id_counter::Counter
)
    n_initial_population = species_creator.n_population + species_creator.n_children
    population = create_individuals(
        ModesIndividualCreator(), 
        rng,
        species_creator.genotype_creator, 
        n_initial_population, 
        individual_id_counter, 
        gene_id_counter
    )
    species = ModesSpecies(species_creator.id, population, species_creator.n_elites)
    return species
end


function get_new_modes_pruned(new_pruned::Vector{<:PruneIndividual})
    new_modes_pruned = [
        ModesIndividual(individual.id, -individual.id, 0, 0, individual.genotype)
        for individual in new_pruned
    ]
    return new_modes_pruned
end

function make_checkpoint_species(
    species::ModesSpecies, new_population::Vector{<:ModesIndividual}, state::State
)
    new_population = reset_tags(new_population)
    new_pruned = perform_modes(species, state)
    sort!(new_pruned, by = individual -> individual.fitness; rev = true)
    pruned_fitnesses = [individual.fitness for individual in new_pruned]
    print_full_summaries(species.id, new_pruned)
    print_prune_summaries(species.id, new_pruned)
    new_modes_pruned = get_new_modes_pruned(new_pruned)
    new_current_state = ModesCheckpointState(
        population = new_population,
        pruned = new_modes_pruned,
        pruned_fitnesses = pruned_fitnesses
    )
    new_species = ModesSpecies(
        id = species.id, 
        n_elites = species.n_elites,
        current_state = new_current_state,
        previous_state = species.current_state,
        all_previous_pruned = union(species.all_previous_pruned, new_modes_pruned)
    )
    return new_species
end

function make_normal_species(species::ModesSpecies, new_population::Vector{<:ModesIndividual})
    new_current_state = ModesCheckpointState(
        population = new_population,
        pruned = get_pruned(species),
        pruned_fitnesses = get_pruned_fitnesses(species)
    )
    new_species = ModesSpecies(
        id = species.id, 
        n_elites = species.n_elites,
        current_state = new_current_state,
        previous_state = species.previous_state,
        all_previous_pruned = species.all_previous_pruned
    )
    return new_species
end

function reset_tags(individuals::Vector{<:ModesIndividual})
    individuals = [
        ModesIndividual(
            individual.id, individual.parent_id, individual.id, individual.age, individual.genotype
        ) 
        for individual in individuals
    ]
    return individuals
end

function create_new_population(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies, 
    evaluation::Evaluation, 
    state::State
)
    rng = get_rng(state)
    elders = replace(species_creator.replacer, rng, species, evaluation)
    parents = select(species_creator.selector, rng, elders, evaluation)
    children = recombine(
        species_creator.recombiner, rng, get_individual_id_counter(state), parents;
    )
    for mutator in species_creator.mutators
        children = mutate(mutator, rng, get_gene_id_counter(state), children)
    end
    new_population = [elders ; children]
    return new_population
end

function add_elite_to_archive(species::ModesSpecies, n_elites::Int, evaluation::Evaluation)
    population_ids = [individual.id for individual in species.population]
    population_records = [record for record in get_records(evaluation, population_ids)]
    elite_individual_id = last(sort(population_records, by = record -> record.fitness)).id
    #elite_individual_fitness = last(sort(population_records, by = record -> record.fitness)).fitness
    elite_individual = find_by_id(species.population, elite_individual_id)
    new_species = add_elites_to_archive(species.elites_archive, n_elites, [elite_individual])
    return new_species
end

function create_species(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies,
    evaluation::Evaluation,
    state::State;
    is_modes_checkpoint::Bool = false
)
    population_length_before = length(species.population)
    new_population = create_new_population(species_creator, species, evaluation, state)
    new_species = is_modes_checkpoint ? 
        make_checkpoint_species(species, new_population, state) :
        make_normal_species(species, new_population)
    new_species = add_elite_to_archive(new_species, species_creator.n_elites, evaluation)
    if population_length_before != length(species.population)
        throw(ErrorException("population length changed"))
    end
    return species
end

function create_species(
    species_creator::ModesSpeciesCreator,
    species::ModesSpecies,
    state::State
) 
    generation = get_generation(state)
    evaluation = get_evaluation(state, species.id)
    using_modes = species_creator.modes_interval > 0
    is_modes_checkpoint = using_modes && generation % species_creator.modes_interval == 0
    new_species = create_species(
        species_creator, species, evaluation, state; is_modes_checkpoint = is_modes_checkpoint
    )
    return new_species
end
    #ids = [individual.id for individual in species.population]
    #parent_ids = [individual.parent_id for individual in species.population]
    #tags = [individual.tag for individual in species.population]
    #generation = get_generation(state)
    #summaries = [(id, parent_id, tag) for (id, parent_id, tag) in zip(ids, parent_ids, tags)]
    #sort!(summaries, by = summary -> summary[1])
    #println("$(species.id)_$generation = ", summaries)
