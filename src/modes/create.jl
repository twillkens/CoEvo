using ...Individuals.Modes: age_individuals

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
end

function create_species(species_creator::ModesSpeciesCreator, state::State)
    n_population = species_creator.n_population
    genotype_creator = species_creator.genotype_creator
    population = create_individuals(
        ModesIndividualCreator(), genotype_creator, n_population, state
    )
    species = ModesSpecies(species_creator.id, population)
    return species
end


function spawn(
    parents::Vector{<:ModesIndividual}, 
    recombiner::Recombiner, 
    mutators::Vector{<:Mutator}, 
    state::State;
    reset_tags::Bool = false
)
    children = recombine(recombiner, parents, state; reset_tags = reset_tags)
    for mutator in mutators
        children = mutate(mutator, children, state)
    end
    return children
end


function replace_worst_with_archive_elites(
    elders::Vector{<:Individual}, archive::AdaptiveArchive, evaluation::Evaluation
)
    n_substitute = length(archive)
    elder_records = get_records(evaluation, [individual.id for individual in elders])
    worst_records = sort(elder_records, by = record -> record.fitness)[1:n_substitute]
    worst_ids = [record.id for record in worst_records]
    filtered_elders = filter(individual -> individual.id ∉ worst_ids, elders)
    recent_elites = get_recent(archive, n_substitute)
    population = [filtered_elders ; recent_elites]
    return population
end

function create_population(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies,
    evaluation::Evaluation,
    state::State;
    reset_tags::Bool = false
)
    population_length_before = length(species.population)
    elders = replace(species_creator.replacer, species, evaluation, state)
    elders = age_individuals(elders)
    parents = select(species_creator.selector, elders, evaluation, state)
    children = spawn(
        parents, species_creator.recombiner, species_creator.mutators, state; 
        reset_tags = reset_tags
    )
    elders = replace_worst_with_archive_elites(elders, species.archive, evaluation) 
    population = [elders ; children]
    if population_length_before != length(population)
        throw(ErrorException("population length changed"))
    end
    return population
end

add_to_archive!(species::ModesSpecies, adaptive_elites::Vector{<:Individual}) = 
    add_to_archive!(species.archive, adaptive_elites)

function perform_modes!(species::ModesSpecies, state::State)
    pruned_individuals = perform_modes(species, state)
    empty!(species.previous_pruned_individuals)
    append!(species.previous_pruned_individuals, species.pruned_individuals)
    empty!(species.pruned_individuals)
    append!(species.pruned_individuals, pruned_individuals)
    best_id = last(sort(pruned_individuals, by = individual -> individual.fitness))
    modes_elite = find_by_id(pruned_individuals, best_id)
    add_to_archive!(species.archive, modes_elite)
end

function create_species(
    species_creator::ModesSpeciesCreator,
    species::ModesSpecies,
    evaluation::Evaluation,
    state::State
) 
    generation = get_generation(state)
    is_modes_checkpoint = generation % 50 == 0
    if is_modes_checkpoint
        perform_modes!(species, state)
    end
    new_population = create_population(
        species_creator, species, evaluation, state; reset_tags = is_modes_checkpoint
    )
    new_species = ModesSpecies(species.id, new_population, species.population, species.archive)
    return new_species
end
