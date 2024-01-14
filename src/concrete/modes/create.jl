
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

using StatsBase: sample

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
            elite_ids = get_elite_ids(species),
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
    n_elite_ids = min(length(get_elites(species)), 25)
    all_elite_ids = [individual.id for individual in get_elites(species)]
    elite_ids = sample(get_rng(state), all_elite_ids, n_elite_ids; replace = false)
    #println("new_population = ", [individual.id for individual in new_population])
    new_current_state = ModesCheckpointState(
        population = new_population,
        pruned = new_modes_pruned,
        pruned_fitnesses = pruned_fitnesses,
        elites = get_elites(species),
        elite_ids = elite_ids,
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

using ...Species.Modes: get_elite_ids

function make_normal_species(
    species::ModesSpecies, new_population::Vector{<:ModesIndividual}, state::State
)
    #println("make_normal_species")
    n_elite_ids = min(length(get_elites(species)), 25)
    all_elite_ids = [individual.id for individual in get_elites(species)]
    elite_ids = sample(get_rng(state), all_elite_ids, n_elite_ids; replace = false)
    new_current_state = ModesCheckpointState(
        population = new_population,
        pruned = get_pruned(species),
        pruned_fitnesses = get_pruned_fitnesses(species),
        elites = get_elites(species),
        elite_ids = elite_ids
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

using ..Mutators.FunctionGraphs: FunctionGraphMutator
using ..Abstract.States: get_trial

function create_new_population(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies, 
    evaluation::Evaluation, 
    state::State
)
    rng = get_rng(state)
    #ids_fitness = [(record.id, record.fitness) for record in evaluation.records]
    #println("fitnesses: $ids_fitness")
    #println("individual_id_counter_before = ", get_individual_id_counter(state).current_value)
    #println("gene_id_counter_before = ", get_gene_id_counter(state).current_value)
    elders = replace(species_creator.replacer, rng, species, evaluation)
    #elder_clones = recombine(
    #    species_creator.recombiner, rng, get_individual_id_counter(state), elders;
    #)
    #noise_mutator = FunctionGraphMutator(mutation_probabilities = Dict(:identity => 1.0), noise_std = 0.1)
    #elder_mutants =  mutate(noise_mutator, rng, get_gene_id_counter(state), elder_clones)
    #println("elders = ", [elder.id for elder in elders])
    #println("rng_state_elders = ", rng.state)
    parents = select(species_creator.selector, rng, elders, evaluation)
    #println("parents = ", [parent.id for parent in parents])
    #println("rng_state_parents = ", rng.state)
    children = recombine(
        species_creator.recombiner, get_individual_id_counter(state), get_trial(state), parents;
    )
    #println("children = ", [child.id for child in children])
    #println("rng_state_children = ", rng.state)
    #println("parents = ", [parent.id for parent in parents])
    #println("children = ", [child.id for child in children])
    for mutator in species_creator.mutators
        children = mutate(mutator, rng, get_gene_id_counter(state), children)
    end
    #println("individual_id_counter_after = ", get_individual_id_counter(state).current_value)
    #println("gene_id_counter_after = ", get_gene_id_counter(state).current_value)
    #println("rng_state_mutation = ", rng.state)
    new_population = [elders ; children]
    #new_population = [elder_clones ; children]
    #new_population = [elder_mutants ; children]
    return new_population
end

using StatsBase: sample

using ...Species.Modes: get_elites

function add_elite_to_archive(
    species::ModesSpecies, n_elites::Int, evaluation::Evaluation, state::State
)
    population_ids = [individual.id for individual in get_population(species)]
    population_records = [record for record in get_records(evaluation, population_ids)]
    population_records = filter(record -> record.rank == 1 && record.crowding == Inf, population_records)
    elite_ids = [record.id for record in population_records]
    elites = [individual for individual in get_population(species) if individual.id in elite_ids]

    #elite_individual_id = last(sort(population_records, by = record -> record.fitness)).id
    #elite_individual_fitness = last(sort(population_records, by = record -> record.fitness)).fitness
    #elite_individual = find_by_id(get_population(species), elite_individual_id)
    #new_species = add_elites_to_archive(species, n_elites, [elite_individual])
    new_species = add_elites_to_archive(species, 1000, elites)
    #println("elites_archive_length = ", length(get_elites(new_species)))
    flush(stdout)
    return new_species
end

function get_nsew(trial::Int, n_x::Int, n_y::Int)
    # Calculate the row and column of the trial
    row, col = divrem(trial - 1, n_x) .+ 1

    # Calculate the neighbors with toroidal wrapping
    north = ((row - 2 + n_y) % n_y) * n_x + col
    south = (row % n_y) * n_x + col
    east = (row - 1) * n_x + (col % n_x) + 1
    west = (row - 1) * n_x + ((col - 2 + n_x) % n_x) + 1

    return [north, south, east, west]
end

function get_cardinal_directions(trial::Int, n_x::Int, n_y::Int)
    # Calculate the row and column of the trial
    row, col = divrem(trial - 1, n_x) .+ 1

    # Calculate the primary directions with toroidal wrapping
    north = ((row - 2 + n_y) % n_y) * n_x + col
    south = (row % n_y) * n_x + col
    east = (row - 1) * n_x + (col % n_x) + 1
    west = (row - 1) * n_x + ((col - 2 + n_x) % n_x) + 1

    # Calculate the diagonal directions with toroidal wrapping
    northeast = ((row - 2 + n_y) % n_y) * n_x + (col % n_x) + 1
    northwest = ((row - 2 + n_y) % n_y) * n_x + ((col - 2 + n_x) % n_x) + 1
    southeast = (row % n_y) * n_x + (col % n_x) + 1
    southwest = (row % n_y) * n_x + ((col - 2 + n_x) % n_x) + 1

    return [north, south, east, west, northeast, northwest, southeast, southwest]
end

function even_grid(n::Int)
    # Check if n is a perfect square
    if isqrt(n)^2 == n
        return (isqrt(n), isqrt(n))
    end

    # Find factors of n that are as close as possible to each other
    for i in reverse(1:isqrt(n))
        if n % i == 0
            return (i, n ÷ i)
        end
    end

    # If no suitable factors found, throw an error
    throw(ArgumentError("Cannot create an even grid with $n elements"))
end
using HDF5: h5open, read, File
using ...Genotypes: load_genotype

function load_migration_individuals(file::File, species_creator::ModesSpeciesCreator, state::State)
    base_path = "$(species_creator.id)"
    individuals = []
    genotype_creator = species_creator.genotype_creator
    individual_ids = sort(parse.(Int, keys(file[base_path])))
    for individual_id in individual_ids
        individual_path = "$base_path/$individual_id"
        individual = ModesIndividual(
            individual_id, 
            read(file["$individual_path/parent_id"]),
            read(file["$individual_path/tag"]),
            read(file["$individual_path/age"]),
            load_genotype(file, "$individual_path/genotype", genotype_creator),
        )
        push!(individuals, individual)
    end
    individuals = [individual for individual in individuals]
    individuals = recombine(
        species_creator.recombiner, get_individual_id_counter(state), get_trial(state), individuals;
    )
    return individuals
end

using ...Replacers.Truncation: TruncationReplacer
function clip_last_subfield(directory::String)
    parts = split(directory, "/")
    return join(parts[1:end-1], "/")
end

function get_root_directory(config)
    root_directory = joinpath(ENV["COEVO_TRIAL_DIR"], clip_last_subfield(config.id))
    return root_directory
end

function load_migration_elites(species_creator::ModesSpeciesCreator, nsew_trials::Vector{Int}, state::State)
    root_directory = get_root_directory(state.configuration)
    println("root_directory = ", root_directory)
    all_migration_elites = []
    target_generation = get_generation(state) - 1

    for trial in nsew_trials
        trial_path = joinpath(root_directory, string(trial), "generations", string(target_generation) * ".h5")
        file_loaded = false

        while !file_loaded
            try
                # Check if the file exists
                if isfile(trial_path)
                    file = h5open(trial_path, "r")

                    # Check if "valid" exists in the keys
                    if "valid" in keys(file)
                        elites = load_migration_individuals(file, species_creator, state)
                        append!(all_migration_elites, elites)
                        file_loaded = true
                    else
                        # If "valid" does not exist, sleep and retry
                        sleep(10)
                    end
                else
                    # If file does not exist, sleep and retry
                    sleep(10)
                end
            catch e
                @warn "Error opening file: $(e)"
                sleep(10)  # Sleep after catching an error
            end
        end
    end

    all_migration_elites = [elite for elite in all_migration_elites]
    return all_migration_elites
end

using ..Species: get_population

function create_migration_population(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies,
    state::State
)
    original_length = length(get_population(species))
    n_trials = state.configuration.globals.n_trials
    x, y = even_grid(n_trials)
    trial = get_trial(state)
    nsew_trials = get_nsew(trial, x, y)
    migration_elites = load_migration_elites(species_creator, nsew_trials, state)
    n_truncate = length(migration_elites)
    replacer = TruncationReplacer(n_truncate)
    natives = replace(replacer, get_rng(state), species, get_evaluation(state, species.id))
    new_population = [natives ; migration_elites]
    if length(new_population) != original_length
        throw(ErrorException("population length changed"))
    end
    return new_population
end


function create_species(
    species_creator::ModesSpeciesCreator, 
    species::ModesSpecies,
    evaluation::Evaluation,
    state::State;
    is_modes_checkpoint::Bool = false
)
    #new_species = add_elite_to_archive(species, species_creator.n_elites, evaluation)
    if get_generation(state) % 20 == 0
        species = add_elite_to_archive(species, species_creator.n_elites, evaluation, state)
    end
    population_length_before = length(get_population(species))
    new_population = is_modes_checkpoint ? 
        create_migration_population(species_creator, species, state) :
        create_new_population(species_creator, species, evaluation, state)
    species = is_modes_checkpoint ? 
        make_checkpoint_species(species, new_population, state) :
        make_normal_species(species, new_population, state)
    if population_length_before != length(get_population(species))
        throw(ErrorException("population length changed"))
    end
    return species
end

import ...Results: get_individual_outcomes

function create_species(
    species_creator::ModesSpeciesCreator,
    species::ModesSpecies,
    state::State
) 
    #println("------species_id = ", species.id, "---------")
    #println("ids_current = ", [
    #    (individual.id, individual.parent_id, individual.tag) 
    #    for individual in get_population(species)]
    #)
    #if get_generation(state) == 21
    #    println("genotypes_$(species.id) = ", [
    #        (individual.id, individual.genotype) 
    #        for individual in get_population(species)]
    #    )
    #    println("individual_outcomes_$(species.id) = ", get_individual_outcomes(state.results))
    #end
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
    #if is_modes_checkpoint
    #    println("disco_info_$(species.id) = "[
    #        (record.rank, round(record.crowding, digits=3), round(record.fitness, digits=3)) 
    #        for record in evaluation.records]
    #    )
    #end
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
    #println("rng_state_before_creation: ", get_rng(state).state)
    all_new_species = [
        create_species(species_creator, species, state)
        for (species_creator, species) in zip(species_creators, all_species)
    ]
    #println("rng_state_after_creation: ", get_rng(state).state)
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
        #println("rng_state_after_modes = ", get_rng(state).state)
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
