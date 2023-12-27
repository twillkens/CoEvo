
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
using ...Species: get_elites
using ...Species: get_population


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
    species = ModesSpecies(species_creator.id, population)
    return species
end

function create_species(species_creator::ModesSpeciesCreator, state::State)
    rng = get_rng(state)
    individual_id_counter = get_individual_id_counter(state)
    gene_id_counter = get_gene_id_counter(state)
    species = create_species(species_creator, rng, individual_id_counter, gene_id_counter)
    return species
end


function get_new_modes_pruned(new_pruned::Vector{<:PruneIndividual})
    new_modes_pruned = [
        ModesIndividual(individual.id, -individual.id, 0, 0, individual.genotype)
        for individual in new_pruned
    ]
    return new_modes_pruned
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


function make_checkpoint_species(
    species::ModesSpecies, new_population::Vector{I}, state::State
) where {I <: ModesIndividual}
    #println("make_checkpoint_species")
    #println("generation in make_checkpoint_species = ", get_generation(state))
    species = ModesSpecies(
        id = species.id, 
        current_state = ModesCheckpointState(
            population = new_population,
            pruned = I[],
            pruned_fitnesses = Float64[],
            elites = get_elites(species),
        ),
        previous_state = species.previous_state,
        all_previous_pruned = species.all_previous_pruned,
        change = species.change,
        novelty = species.novelty,
    )
    #println("rng_before_modes = ", get_rng(state).state)
    new_pruned = perform_modes(species, state)
    #println("rng_after_modes = ", get_rng(state).state)
    sort!(new_pruned, by = individual -> individual.fitness; rev = true)
    pruned_fitnesses = [individual.fitness for individual in new_pruned]
    print_full_summaries(species.id, new_pruned)
    print_prune_summaries(species.id, new_pruned)
    new_modes_pruned = get_new_modes_pruned(new_pruned)
    new_population = reset_tags(new_population)
    #println("new_population = ", [individual.id for individual in new_population])
    new_current_state = ModesCheckpointState(
        population = new_population,
        pruned = new_modes_pruned,
        pruned_fitnesses = pruned_fitnesses,
        elites = get_elites(species)
    )
    #new_pruned_genotypes = Set(individual.genotype for individual in new_modes_pruned)
    #new_species = ModesSpecies(
    #    id = species.id, 
    #    current_state = new_current_state,
    #    previous_state = new_current_state,
    #    all_previous_pruned = union(species.all_previous_pruned, new_pruned_genotypes)
    #)
    new_species = ModesSpecies(
        id = species.id, 
        current_state = new_current_state,
        previous_state = species.previous_state,
        all_previous_pruned = species.all_previous_pruned,
        change = species.change,
        novelty = species.novelty,
    )
    return new_species
end


function make_normal_species(species::ModesSpecies, new_population::Vector{<:ModesIndividual})
    #println("make_normal_species")
    new_current_state = ModesCheckpointState(
        population = new_population,
        pruned = get_pruned(species),
        pruned_fitnesses = get_pruned_fitnesses(species),
        elites = get_elites(species)
    )
    new_species = ModesSpecies(
        id = species.id, 
        current_state = new_current_state,
        previous_state = species.previous_state,
        all_previous_pruned = species.all_previous_pruned,
        change = species.change,
        novelty = species.novelty,
    )
    return new_species
end


function create_new_population(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies, 
    evaluation::Evaluation, 
    state::State
)
    rng = get_rng(state)
    elders = replace(species_creator.replacer, rng, species, evaluation)
    #println("elders = ", [elder.id for elder in elders])
    #println("rng_state_elders = ", rng.state)
    parents = select(species_creator.selector, rng, elders, evaluation)
    #println("parents = ", [parent.id for parent in parents])
    #println("rng_state_parents = ", rng.state)
    children = recombine(
        species_creator.recombiner, rng, get_individual_id_counter(state), parents;
    )
    #println("children = ", [child.id for child in children])
    #println("rng_state_children = ", rng.state)
    #println("parents = ", [parent.id for parent in parents])
    #println("children = ", [child.id for child in children])
    for mutator in species_creator.mutators
        children = mutate(mutator, rng, get_gene_id_counter(state), children)
    end
    new_population = [elders ; children]
    return new_population
end

function add_elite_to_archive(species::ModesSpecies, n_elites::Int, evaluation::Evaluation)
    population_ids = [individual.id for individual in get_population(species)]
    population_records = [record for record in get_records(evaluation, population_ids)]
    elite_individual_id = last(sort(population_records, by = record -> record.fitness)).id
    #elite_individual_fitness = last(sort(population_records, by = record -> record.fitness)).fitness
    elite_individual = find_by_id(get_population(species), elite_individual_id)
    new_species = add_elites_to_archive(species, n_elites, [elite_individual])
    return new_species
end


function create_species(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies,
    evaluation::Evaluation,
    state::State;
    is_modes_checkpoint::Bool = false
)
    #new_species = add_elite_to_archive(species, species_creator.n_elites, evaluation)
    species = add_elite_to_archive(species, species_creator.n_elites, evaluation)
    population_length_before = length(get_population(species))
    new_population = create_new_population(species_creator, species, evaluation, state)
    species = is_modes_checkpoint ? 
        make_checkpoint_species(species, new_population, state) :
        make_normal_species(species, new_population)
    if population_length_before != length(get_population(species))
        throw(ErrorException("population length changed"))
    end
    return species
end

function create_species(
    species_creator::ModesSpeciesCreator,
    species::ModesSpecies,
    state::State
) 
    #println("------species.id = ", species.id, "---------")
    #println("ids_current = ", [
    #    (individual.id, individual.parent_id, individual.tag) 
    #    for individual in get_population(species)]
    #)
    #println("ids_previous = ", [
    #    (individual.id, individual.parent_id, individual.tag) 
    #    for individual in get_previous_population(species)]
    #)
    #println("ids_previous = ", [individual.id for individual in get_previous_population(species)])
    #println("tags_current = ", [individual.tag for individual in get_population(species)])
    #println("tags_previous = ", [individual.tag for individual in get_previous_population(species)])
    generation = get_generation(state)
    evaluation = get_evaluation(state, species.id)
    using_modes = species_creator.modes_interval > 0
    is_modes_checkpoint = using_modes && generation % species_creator.modes_interval == 0
    new_species = create_species(
        species_creator, species, evaluation, state; is_modes_checkpoint = is_modes_checkpoint
    )
    #println("ids_new = ", [individual.id for individual in get_population(new_species)])
    #println("$(species.id)_$generation = ", [individual.id for individual in get_population(new_species)])
    return new_species
end

using ...Species.Modes: get_pruned_genotypes, get_all_previous_pruned_genotypes
using ...Species.Modes: get_previous_pruned_genotypes

function measure_novelty(all_species::Vector{<:ModesSpecies})
    pruned_genotypes = Set(get_pruned_genotypes(all_species))
    all_previous_pruned_genotypes = get_all_previous_pruned_genotypes(all_species)
    new_genotypes = setdiff(pruned_genotypes, all_previous_pruned_genotypes)
    novelty = length(new_genotypes)
    return novelty
end

function measure_change(all_species::Vector{<:ModesSpecies})
    pruned_genotypes = Set(get_pruned_genotypes(all_species))
    previous_pruned_genotypes = Set(get_previous_pruned_genotypes(all_species))
    new_genotypes = setdiff(pruned_genotypes, previous_pruned_genotypes)
    change = length(new_genotypes)
    return change
end

function create_species(
    species_creators::Vector{<:ModesSpeciesCreator}, 
    all_species::Vector{S}, 
    state::State
) where {S <: ModesSpecies}
    all_new_species = [
        create_species(species_creator, species, state)
        for (species_creator, species) in zip(species_creators, all_species)
    ]
    using_modes = first(species_creators).modes_interval > 0
    is_modes_checkpoint = using_modes && get_generation(state) % first(species_creators).modes_interval == 0
    if is_modes_checkpoint
        novelty = measure_novelty(all_new_species)
        change = measure_change(all_new_species)
        all_final_species = S[]
        for species in all_new_species
            new_all_previous_pruned = union(species.all_previous_pruned, Set(get_pruned_genotypes(species)))
            final_species = ModesSpecies(
                id = species.id, 
                current_state = species.current_state,
                previous_state = species.current_state,
                all_previous_pruned = new_all_previous_pruned,
                change = change,
                novelty = novelty,
            )
            push!(all_final_species, final_species)
        end
    else
        all_final_species = all_new_species
    end
    return all_final_species
end
    #ids = [individual.id for individual in species.population]
    #parent_ids = [individual.parent_id for individual in species.population]
    #tags = [individual.tag for individual in species.population]
    #generation = get_generation(state)
    #summaries = [(id, parent_id, tag) for (id, parent_id, tag) in zip(ids, parent_ids, tags)]
    #sort!(summaries, by = summary -> summary[1])
    #println("$(species.id)_$generation = ", summaries)
