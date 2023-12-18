using ...Individuals.Modes: age_individuals
using ...Counters: Counter, count!
using ...Abstract.States: get_generation
using ...Genotypes: get_size
using ...Abstract.States: get_rng, get_individual_id_counter, get_gene_id_counter
using ..Abstract.States: get_evaluation
using ...Species.Modes: add_to_archive!

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
    genotype_creator::G
    phenotype_creator::P
    evaluator::E
    replacer::RP
    selector::S
    recombiner::RC
    mutators::Vector{M}
    modes_interval::Int
    adaptive_archive_length::Int
    elites_archive_length::Int
end

function create_species(
    species_creator::ModesSpeciesCreator, 
    rng::AbstractRNG, 
    individual_id_counter::Counter, 
    gene_id_counter::Counter
)
    n_population = species_creator.n_population
    genotype_creator = species_creator.genotype_creator
    population = create_individuals(
        ModesIndividualCreator(), 
        rng,
        genotype_creator, 
        n_population + species_creator.n_children,
        individual_id_counter, 
        gene_id_counter
    )
    species = ModesSpecies(
        species_creator.id, population, species_creator.adaptive_archive_length,
        species_creator.elites_archive_length
    )
    return species
end

function make_modes_species(
    species::ModesSpecies, new_population::Vector{<:ModesIndividual}, state::State
)
    new_pruned = perform_modes(species, state)
    new_modes_pruned = [
        ModesIndividual(individual.id, -individual.id, 0, 0, individual.genotype)
        for individual in new_pruned
    ]
    add_to_archive!(species.adaptive_archive, new_modes_pruned)
    species = ModesSpecies(
        id = species.id, 
        population = new_population, 
        previous_population = new_population, 
        pruned = new_modes_pruned,
        previous_pruned = copy(species.pruned), 
        all_previous_pruned = union(species.all_previous_pruned, species.pruned),
        adaptive_archive = species.adaptiue_archive,
        elites_archive = species.elites_archive,
        previous_adaptive = copy(species.adaptive_archive.individuals),
        previous_elites = copy(species.elites_archive.individuals),
    )
    return species
end

function make_normal_species(
    species::ModesSpecies, new_population::Vector{<:ModesIndividual}
)
    species = ModesSpecies(
        id = species.id, 
        population = new_population, 
        previous_population = copy(species.previous_population), 
        pruned = copy(species.pruned),
        previous_pruned = copy(species.previous_pruned),
        all_previous_pruned = copy(species.all_previous_pruned),
        adaptive_archive = species.adaptive_archive,
        elites_archive = species.elites_archive,
        previous_adaptive = copy(species.previous_adaptive),
        previous_elites = copy(species.previous_elites),
    )
    return species
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

function create_species(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies,
    evaluation::Evaluation,
    state::State;
    is_modes_checkpoint::Bool = false
)
    population_length_before = length(species.population)
    rng = get_rng(state)
    elders = replace(species_creator.replacer, rng, species, evaluation)
    #println("elder_ids = ", [individual.id for individual in elders])
    parents = select(species_creator.selector, rng, elders, evaluation)
    #println("parent_ids = ", [individual.id for individual in parents])
    children = recombine(
        species_creator.recombiner, rng, get_individual_id_counter(state), parents;
    )
    #println("child_ids = ", [individual.id for individual in children])
    for mutator in species_creator.mutators
        children = mutate(mutator, rng, get_gene_id_counter(state), children)
    end
    new_population = [elders ; children]
    if is_modes_checkpoint
        new_population = reset_tags(new_population)
        species = make_modes_species(species, new_population, state)
    else
        species = make_normal_species(species, new_population)
    end
    #println("population length after: ", length(population))
    if population_length_before != length(species.population)
        throw(ErrorException("population length changed"))
    end
    return species
end

function add_elite_to_archive!(species::ModesSpecies, evaluation::Evaluation)
    population_ids = [individual.id for individual in species.population]
    population_records = [record for record in get_records(evaluation, population_ids)]
    elite_individual_id = last(sort(population_records, by = record -> record.fitness)).id
    #elite_individual_fitness = last(sort(population_records, by = record -> record.fitness)).fitness
    elite_individual = find_by_id(species.population, elite_individual_id)
    add_to_archive!(species.elites_archive, [elite_individual])
end

function create_species(
    species_creator::ModesSpeciesCreator,
    species::ModesSpecies,
    state::State
) 
    generation = get_generation(state)
    ids = [individual.id for individual in species.population]
    parent_ids = [individual.parent_id for individual in species.population]
    tags = [individual.tag for individual in species.population]
    generation = get_generation(state)
    summaries = [(id, parent_id, tag) for (id, parent_id, tag) in zip(ids, parent_ids, tags)]
    sort!(summaries, by = summary -> summary[1])
    #println("$(species.id)_$generation = ", summaries)

    evaluation = get_evaluation(state, species.id)
    add_elite_to_archive!(species, evaluation)
    using_modes = species_creator.modes_interval > 0
    is_modes_checkpoint = using_modes && generation % species_creator.modes_interval == 0
    new_species = create_species(
        species_creator, species, evaluation, state; is_modes_checkpoint = is_modes_checkpoint
    )
    return new_species
end
    #rank_one_records = [record for record in filter(record -> record.rank == 1, population_records)]
    #winner = run_tournament(get_rng(state), rank_one_records)
    #winner = find_by_id(species.population, winner.id)
    #elites = [winner]
    ##elites = [find_by_id(species.population, id) for id in rank_one_ids]
    ##println("elites: ", [individual.id for individual in elites])
    ##elites = [rand(get_rng(state), elites)]

    ##println("elite_individual: ", elite_individual.id, " ", elite_individual_fitness)
    #add_to_archive!(species.elites_archive, elites)
    #add_to_archive!(species.elites_archive, [elite_individual])
    
    #println("population length before: ", population_length_before)
    #println("----$(generation)-$(species.id)------")
    #population_ids = [individual.id for individual in species.population]
    #println("population_ids: ", population_ids)
    #tags = [individual.tag for individual in species.population]
    #println("tags: ", tags)
    #previous_population_ids = [individual.id for individual in species.previous_population]
    #println("previous_population_ids: ", previous_population_ids)
    #previous_population_tags = [individual.tag for individual in species.previous_population]
    #println("previous_population_tags: ", previous_population_tags)
    #pruned_ids = [individual.id for individual in species.pruned]
    #println("pruned_ids: ", pruned_ids)
    #previous_pruned_ids = [individual.id for individual in species.previous_pruned]
    #println("previous_pruned_ids: ", previous_pruned_ids)
    #previous_pruned_ids = [individual.id for individual in species.previous_pruned]
    #println("previous_pruned_ids: ", previous_pruned_ids)
    #all_previous_pruned_ids = [individual.id for individual in species.all_previous_pruned]
    #println("all_previous_pruned_ids: ", all_previous_pruned_ids)
    #archive_ids = [individual.id for individual in species.archive.individuals]
    #println("archive_ids: ", archive_ids)
    #elite_archive_ids = [individual.id for individual in species.elites_archive.individuals]
    #println("elite_archive_ids: ", elite_archive_ids)

#function replace_worst_with_archive_elites(
#    elders::Vector{<:Individual}, archive_clones::Vector{<:Individual}, evaluation::Evaluation
#)
#    length_elders_before = length(elders)
#    n_substitute = length(archive_clones)
#    #println("n_substitute: ", n_substitute)
#    elder_records = get_records(evaluation, [individual.id for individual in elders])
#    #println("length_elder_records = ", length(elder_records))
#    worst_records = sort(elder_records, by = record -> record.fitness)[1:n_substitute]
#    worst_fitnesses = [record.fitness for record in worst_records]
#    #println("length_worst_records = ", length(worst_records))
#    worst_ids = [record.id for record in worst_records]
#    worst_individuals = [find_by_id(elders, id) for id in worst_ids]
#    worst_sizes = [get_size(individual.genotype) for individual in worst_individuals]
#    worst_summaries = [(fitness, size) for (fitness, size) in zip(worst_fitnesses, worst_sizes)]
#    println("worst_summaries: ", worst_summaries)
#    clone_sizes = [get_size(individual.genotype) for individual in archive_clones]
#    println("clone_sizes: ", clone_sizes)
#    #println("length_worst_ids = ", length(worst_ids))
#    filtered_elders = filter(individual -> individual.id ∉ worst_ids, elders)
#    #println("length_filtered_elders = ", length(filtered_elders))
#    population = [filtered_elders ; archive_clones]
#    length_elders_after = length(population)
#    #println("elder records: ", elder_records)
#    #println("worst records: ", worst_records)
#    #println("worst ids: ", worst_ids)
#    #println("length_elders_before: ", length_elders_before)
#    #println("length_elders_after: ", length_elders_after)
#    if length_elders_before != length_elders_after
#        throw(ErrorException("length_elders changed"))
#    end
#    return filtered_elders, archive_clones
#end

    #println("new_pruned: ", [individual.id for individual in new_pruned])
    #new_pruned, new_elite = find_new_elite(new_pruned)
    #add_to_archive!(species.archive, [new_elite])
    #add_to_archive!(species.archive, new_pruned)

#function make_archive_clones(species::ModesSpecies, state::State)
#    rng = get_rng(state)
#    individual_id_counter = get_individual_id_counter(state)
#    #individuals = [species.archive.individuals[end] for _ in eachindex(species.archive)]
#    archive_elite_clones = recombine(
#        CloneRecombiner(), rng, individual_id_counter, species.archive.individuals
#    )
#    return archive_elite_clones
#end

#function find_new_elite(new_pruned::Vector{<:Individual})
#    println("new_pruned = ",
#        [(individual.id, get_size(individual.genotype), round(individual.fitness, digits=3)) 
#        for individual in new_pruned]
#    )
#    best_id = last(sort(new_pruned, by = individual -> individual.fitness)).id
#    new_modes_full = [
#        ModesIndividual(individual.id, -individual.id, 0, 0, individual.full_genotype)
#        for individual in new_pruned
#    ]
#    new_modes_pruned = [
#        ModesIndividual(individual.id, -individual.id, 0, 0, individual.genotype)
#        for individual in new_pruned
#    ]
#    new_elite = find_by_id(new_modes_full, best_id)
#    println("new_elite: ", new_elite.id)
#    return new_modes_pruned, new_elite
#end