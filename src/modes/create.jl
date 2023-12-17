using ...Individuals.Modes: age_individuals
using ...Counters: Counter, count!
using ...Abstract.States: get_generation

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
    max_archive_size::Int
    n_sample::Int
    modes_interval::Int
end

function create_species(
    species_creator::ModesSpeciesCreator, 
    rng::AbstractRNG, 
    individual_id_counter::Counter, 
    gene_id_counter::Counter
)
    n_population = species_creator.n_population + species_creator.n_children
    genotype_creator = species_creator.genotype_creator
    population = create_individuals(
        ModesIndividualCreator(), 
        rng,
        genotype_creator, 
        n_population, 
        individual_id_counter, 
        gene_id_counter
    )
    species = ModesSpecies(species_creator.id, population, species_creator.max_archive_size)
    return species
end


function spawn(
    parents::Vector{<:ModesIndividual}, 
    recombiner::Recombiner, 
    mutators::Vector{<:Mutator}, 
    state::State
)
    rng = get_rng(state)
    individual_id_counter = get_individual_id_counter(state)
    gene_id_counter = get_gene_id_counter(state)
    children = recombine(recombiner, rng, individual_id_counter, parents)
    for mutator in mutators
        children = mutate(mutator, rng, gene_id_counter, children)
    end
    return children
end


function replace_worst_with_archive_elites(
    elders::Vector{<:Individual}, archive_clones::Vector{<:Individual}, evaluation::Evaluation
)
    length_elders_before = length(elders)
    n_substitute = length(archive_clones)
    #println("n_substitute: ", n_substitute)
    elder_records = get_records(evaluation, [individual.id for individual in elders])
    #println("length_elder_records = ", length(elder_records))
    worst_records = sort(elder_records, by = record -> record.fitness)[1:n_substitute]
    #println("length_worst_records = ", length(worst_records))
    worst_ids = [record.id for record in worst_records]
    #println("length_worst_ids = ", length(worst_ids))
    filtered_elders = filter(individual -> individual.id ∉ worst_ids, elders)
    #println("length_filtered_elders = ", length(filtered_elders))
    population = [filtered_elders ; archive_clones]
    length_elders_after = length(population)
    #println("elder records: ", elder_records)
    #println("worst records: ", worst_records)
    #println("worst ids: ", worst_ids)
    #println("length_elders_before: ", length_elders_before)
    #println("length_elders_after: ", length_elders_after)
    if length_elders_before != length_elders_after
        throw(ErrorException("length_elders changed"))
    end
    return filtered_elders, archive_clones
end

using ...Abstract.States: get_rng, get_individual_id_counter, get_gene_id_counter

function make_archive_clones(species::ModesSpecies, state::State)
    rng = get_rng(state)
    individual_id_counter = get_individual_id_counter(state)
    individuals = [species.archive.individuals[end] for _ in eachindex(species.archive)]
    archive_elite_clones = recombine(
        CloneRecombiner(), rng, individual_id_counter, individuals
    )
    return archive_elite_clones
end

function find_new_elite(new_pruned::Vector{<:Individual})
    best_id = last(sort(new_pruned, by = individual -> individual.fitness)).id
    new_modes_full = [
        ModesIndividual(individual.id, -individual.id, 0, 0, individual.full_genotype)
        for individual in new_pruned
    ]
    new_modes_pruned = [
        ModesIndividual(individual.id, -individual.id, 0, 0, individual.genotype)
        for individual in new_pruned
    ]
    new_elite = find_by_id(new_modes_full, best_id)
    return new_modes_pruned, new_elite
end

function make_modes_species(
    species::ModesSpecies, new_population::Vector{<:ModesIndividual}, state::State
)
    new_pruned = perform_modes(species, state)
    #println("new_pruned: ", [individual.id for individual in new_pruned])
    new_pruned, new_elite = find_new_elite(new_pruned)
    add_to_archive!(species.archive, [new_elite])
    species = ModesSpecies(
        id = species.id, 
        population = new_population, 
        previous_population = new_population, 
        pruned = new_pruned,
        previous_pruned = copy(species.pruned), 
        all_previous_pruned = union(species.all_previous_pruned, species.pruned),
        archive = species.archive
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
        archive = species.archive
    )
    return species
end

function create_species(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies,
    evaluation::Evaluation,
    state::State;
    is_modes_checkpoint::Bool = false
)
    population_length_before = length(species.population)
    
    #println("population length before: ", population_length_before)
    rng = get_rng(state)

    elders = replace(species_creator.replacer, rng, species, evaluation)
    #println("elders_length: ", length(elders))
    elders = age_individuals(elders)
    parents = select(species_creator.selector, rng, elders, evaluation)
    #println("parents_length: ", length(parents))
    children = spawn(
        parents, species_creator.recombiner, species_creator.mutators, state; 
    )
    if is_modes_checkpoint
        #archive_clones = make_archive_clones(species, state)
        if length(species.archive.individuals) > 0
            last_archive_individual = species.archive.individuals[end]
            x = [last_archive_individual for _ in eachindex(species.archive.individuals)]
            mutants = spawn(x, species_creator.recombiner, species_creator.mutators, state)
            elders, archive_clones = replace_worst_with_archive_elites(elders, mutants, evaluation) 
            new_population = [elders ; archive_clones ; children]
        else
            new_population = [elders ; children]
        end
        new_population = [
            ModesIndividual(
                individual.id, 
                individual.parent_id, 
                tag,
                individual.age,
                individual.genotype
            ) 
            for (tag, individual) in enumerate(new_population)
        ]
        species = make_modes_species(species, new_population, state)
    else
        new_population = [elders ; children]
        species = make_normal_species(species, new_population)
    end
    #println("population length after: ", length(population))
    if population_length_before != length(species.population)
        throw(ErrorException("population length changed"))
    end
    return species
end

using ..Abstract.States: get_evaluation

function create_species(
    species_creator::ModesSpeciesCreator,
    species::ModesSpecies,
    state::State
) 
    generation = get_generation(state)
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
    evaluation = get_evaluation(state, species.id)
    using_modes = species_creator.modes_interval > 0
    is_modes_checkpoint = using_modes && generation % species_creator.modes_interval == 0
    new_species = create_species(
        species_creator, 
        species, 
        evaluation, 
        state; 
        is_modes_checkpoint = is_modes_checkpoint
    )
    return new_species
end
