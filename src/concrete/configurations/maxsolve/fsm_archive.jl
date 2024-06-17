export FSMArchiver

using DataFrames
using CSV
using ....Abstract
using ....Interfaces
using Serialization
using Random
using StatsBase
using ...Genotypes.FiniteStateMachines: create_random_fsm_genotype


mutable struct FSMArchiver <: Archiver 
    data::DataFrame
    pruner::Any
end

function FSMArchiver(configuration::MaxSolveConfiguration)
    save_file = get_save_file(configuration)
    if isfile(save_file)
        data = CSV.read(save_file, DataFrame)
    else
        data = DataFrame(
            trial = Int[], 
            algorithm = String[],
            generation = Int[], 
            subjective_fitness = Float64[], 
            utility_16 = Float64[], 
            utility_32 = Float64[], 
            utility_64 = Float64[], 
            utility_128 = Float64[], 
            utility_all = Float64[], 
            change = Float64[], 
            novelty = Float64[], 
            full_complexity = Float64[], 
            hopcroft_complexity = Float64[], 
            modes_complexity = Float64[],
            ecology = Float64[], 
            seed = Int[]
        )
    end
    return FSMArchiver(data, nothing)
end

Base.@kwdef mutable struct ModesPruner{E <: Ecosystem, G <: Genotype, P <: Phenotype}
    checkpoint_interval::Int
    previous_ecosystem::E
    previous_pruned::Set{G}
    all_pruned::Set{G}
    all_pruned_vec::Vector{Vector{G}}
    random_16::Vector{P}
    random_32::Vector{P}
    random_64::Vector{P}
    random_128::Vector{P}
end

#function create_random_fsm_genotype(
#    n_states::Int,
#    gene_id_counter::Counter = BasicCounter(),
#    rng::AbstractRNG = Random.GLOBAL_RNG,
#)
#    # Generate state IDs
#    state_ids = [step!(gene_id_counter) for _ in 1:n_states]
#
#    # Randomly assign labels to states
#    ones = Set{Int}()
#    zeros = Set{Int}()
#    for state_id in state_ids
#        if rand(rng, Bool)
#            push!(ones, state_id)
#        else
#            push!(zeros, state_id)
#        end
#    end
#
#    # Create random transitions
#    links = Dict{Tuple{Int, Bool}, Int}()
#    for state_id in state_ids
#        for bit in [true, false]
#            next_state = rand(rng, state_ids)
#            links[(state_id, bit)] = next_state
#        end
#    end
#
#    # Select a random start state
#    start_state = rand(rng, state_ids)
#
#    # Create the FiniteStateMachineGenotype
#    genotype = FiniteStateMachineGenotype(start_state, ones, zeros, links)
#    return genotype
#end

function create_fsm_phenotypes(n_states::Int, n_phenotypes::Int)
    phenotype_creator = DefaultPhenotypeCreator()
    genotypes = [
        create_random_fsm_genotype(n_states)
        for _ in 1:n_phenotypes
    ]
    phenotypes = [create_phenotype(phenotype_creator, genotype, 0) for genotype in genotypes]
    return phenotypes
end

function ModesPruner(state::State)
    G = typeof(state.ecosystem.learner_population[1].genotype)
    random_16 = create_fsm_phenotypes(16, 10_000)
    random_32 = create_fsm_phenotypes(32, 10_000)
    random_64 = create_fsm_phenotypes(64, 10_000)
    random_128 = create_fsm_phenotypes(128, 10_000)
    pruner = ModesPruner(
        checkpoint_interval = state.configuration.n_learner_population, 
        previous_ecosystem = deepcopy(state.ecosystem), 
        previous_pruned = Set{G}(), 
        all_pruned = Set{G}(),
        all_pruned_vec = Vector{Vector{G}}(),
        random_16 = random_16,
        random_32 = random_32,
        random_64 = random_64,
        random_128 = random_128
    )
    return pruner
end

using ...Phenotypes.FiniteStateMachines

function get_fitness(
    learner::FiniteStateMachinePhenotype, tests::Vector{<:FiniteStateMachinePhenotype}
)
    domain = PredictionGameDomain("PreyPredator")
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain)
    fitness = 0.0
    for test in tests
        phenotypes = Phenotype[learner, test]
        environment = create_environment(environment_creator, phenotypes)
        while is_active(environment)
            step!(environment)
        end
        outcome_set = get_outcome_set(environment)
        fitness += outcome_set[1]
        reset!(learner)
        reset!(test)
    end
    return fitness
end

function get_fitness(learner::Individual, tests::Vector{<:FiniteStateMachinePhenotype})
    return get_fitness(learner.phenotype, tests)
end

using ...Mutators.FiniteStateMachines

struct PruningResult{I <: Individual}
    full::I
    hopcroft::I
    modes::I
    fitness::Float64
end

function minimize_fsm_indiv(individual::Individual)
    hopcroft_individual = deepcopy(individual)
    hopcroft_individual.genotype = minimize(hopcroft_individual.genotype)
    hopcroft_individual.phenotype = create_phenotype(DefaultPhenotypeCreator(), hopcroft_individual.genotype, hopcroft_individual.id)
    return hopcroft_individual
end

function get_genes_to_check(individual::Individual)
    genes_to_check = sort([collect(individual.genotype.ones) ; collect(individual.genotype.zeros)]; rev=true)
    genes_to_check = [gene for gene in genes_to_check if gene != individual.genotype.start]
    return genes_to_check
end

function prune_individual(individual::Individual, tests::Vector{<:FiniteStateMachinePhenotype})
    full_individual = deepcopy(individual)
    hopcroft_individual = minimize_fsm_indiv(full_individual)
    if length(hopcroft_individual.genotype) > length(full_individual.genotype)
        error("Hopcroft minimization failed") 
    end
    current_individual = deepcopy(individual)
    genes_to_check = get_genes_to_check(current_individual)
    orig_fitness = get_fitness(current_individual, tests)
    phenotype_creator = DefaultPhenotypeCreator()

    for gene in genes_to_check
        println("Size of genotype = ", length(current_individual.genotype), ", fitness = ", orig_fitness)
        candidate_genotype = remove_state(current_individual.genotype, gene, nothing)
        candidate_phenotype = create_phenotype(
            phenotype_creator, candidate_genotype, current_individual.id
        )
        current_fitness = get_fitness(candidate_phenotype, tests)
        if current_fitness == orig_fitness
            current_individual.genotype = candidate_genotype
            current_individual.phenotype = candidate_phenotype
        end
    end
    pruned_individual = minimize_fsm_indiv(current_individual)
    if length(pruned_individual.genotype) > length(current_individual.genotype)
        error("Pruning failed")
    end
    result = PruningResult(full_individual, hopcroft_individual, pruned_individual, orig_fitness)
    return result
end


function compute_difference(new_genotypes::Set{<:Genotype}, previous_genotypes::Set{<:Genotype})
    difference = 0
    for genotype in new_genotypes
        if !(genotype in previous_genotypes)
            difference += 1
        end
    end
    return difference
end

compute_difference(
    new_genotypes::Vector{<:Genotype}, previous_genotypes::Vector{<:Genotype}
) = compute_difference(Set(new_genotypes), Set(previous_genotypes))

function compute_ecology(new_individuals::Vector{<:Individual})
    genotype_counts = Dict()
    for individual in new_individuals
        if individual.genotype in keys(genotype_counts)
            genotype_counts[individual.genotype] += 1
        else
            genotype_counts[individual.genotype] = 1
        end
    end

        # Calculate the total number of genotypes
    total_genotypes = length(new_individuals)
    # Calculate the Shannon entropy
    ecology_metric = 0.0
    for count in values(genotype_counts)
        p = count / total_genotypes
        ecology_metric -= p * log2(p)
    end
    return ecology_metric
end

using ...Genotypes.FiniteStateMachines

function compute_complexity(genotypes::Set{<:Genotype})
    max_genotype_size = -Inf
    for genotype in genotypes
        genotype_size = length(genotype)
        if genotype_size > max_genotype_size
            max_genotype_size = genotype_size
        end
    end
    return max_genotype_size
end

function get_elite(results::Vector{<:PruningResult})
    elite_fitness = -Inf
    elite = nothing
    for result in results
        if result.fitness > elite_fitness
            elite_fitness = result.fitness
            elite = result
        end
    end
    return elite
end

struct NullGenotype <: Genotype end

Base.@kwdef struct ModesData{G <: Genotype}
    pruned_genotypes::Set{G}
    full_complexity::Float64
    hopcroft_complexity::Float64
    modes_complexity::Float64
    change::Float64
    novelty::Float64
    ecology::Float64
    utility_subjective::Float64
    utility_16::Float64
    utility_32::Float64
    utility_64::Float64
    utility_128::Float64
    utility_all::Float64
end

function NullModesData()
end

using Serialization

function ModesData(pruner::ModesPruner, pruning_results::Vector{<:PruningResult}, state::State)
    shuffle!(pruning_results)
    elite = get_elite(pruning_results)

    full_complexity = length(elite.full.genotype)
    hopcroft_complexity = length(elite.hopcroft.genotype)
    if full_complexity < hopcroft_complexity
        error("Hopcroft minimization failed")
    end
    modes_complexity = length(elite.modes.genotype)
    if full_complexity < modes_complexity
        error("Modes minimization failed")
    end
    pruned_individuals = [result.modes for result in pruning_results]
    pruned_genotypes = [individual.genotype for individual in pruned_individuals]
    #if state.generation % 50 == 0
    #    simple_small = FiniteStateMachineGenotype(
    #        1, Set([1]), Set{Int}(), Dict((1, false) => 1, (1, true) => 1)
    #    )
    #    simple_small = deepcopy(rand(pruner.all_pruned))
    #    push!(pruned_genotypes, simple_small)
    #end
    push!(pruner.all_pruned_vec, pruned_genotypes)
    #serialize("FSM-DATA/whoa/vec_$(state.generation).jls", pruner.all_pruned_vec)
    ecology = compute_ecology(pruned_individuals)
    #pruned_genotypes = Set(individual.genotype for individual in pruned_individuals)
    pruned_genotypes = Set(pruned_genotypes)
    #println("pruned_genotypes = ", pruned_genotypes)
    change = compute_difference(pruned_genotypes, pruner.previous_pruned)
    novelty = compute_difference(pruned_genotypes, pruner.all_pruned)
    fitness_16 = get_fitness(elite.full, pruner.random_16)
    fitness_32 = get_fitness(elite.full, pruner.random_32)
    fitness_64 = get_fitness(elite.full, pruner.random_64)
    fitness_128 = get_fitness(elite.full, pruner.random_128)
    fitness_all = fitness_16 + fitness_32 + fitness_64 + fitness_128

    data = ModesData(
        pruned_genotypes = pruned_genotypes, 
        full_complexity = float(full_complexity), 
        hopcroft_complexity = float(hopcroft_complexity), 
        modes_complexity = float(modes_complexity), 
        change = float(change), 
        novelty = float(novelty), 
        ecology = float(ecology),
        utility_subjective = float(elite.fitness),
        utility_16 = fitness_16 / length(pruner.random_16),
        utility_32 = fitness_32 / length(pruner.random_32),
        utility_64 = fitness_64 / length(pruner.random_64),
        utility_128 = fitness_128 / length(pruner.random_128),
        utility_all = fitness_all / (length(pruner.random_16) + length(pruner.random_32) + length(pruner.random_64) + length(pruner.random_128))
    )
    return data
end

function update!(pruner::ModesPruner, state::State)
    persistent_tags = Set([learner.tag for learner in state.ecosystem.learner_population])
    #println("persistent_tags = ", persistent_tags)
    persistent_individuals = [
        learner for learner in pruner.previous_ecosystem.learner_population 
        if learner.tag in persistent_tags
    ]
    println("length(persistent_individuals) = ", length(persistent_individuals))
    if length(persistent_individuals) == 0
        error("No persistent individuals")
    end
    tests = [pruner.previous_ecosystem.test_population ; pruner.previous_ecosystem.test_children]
    tests = [test.phenotype for test in tests]
    pruning_results = [
        prune_individual(individual, tests) for individual in persistent_individuals
    ]
    modes_data = ModesData(pruner, pruning_results, state)
    pruner.all_pruned = deepcopy(union(pruner.all_pruned, modes_data.pruned_genotypes, pruner.previous_pruned))
    pruner.previous_pruned = deepcopy(modes_data.pruned_genotypes)
    #println("NUMBER ALL PRUNED = ", length(pruner.all_pruned))
    #println("NUMBER PREVIOUS PRUNED = ", length(pruner.previous_pruned))
    for learner in state.ecosystem.learner_population
        learner.tag = learner.id
    end

    for learner in state.ecosystem.learner_children
        learner.tag = learner.parent_id
    end
    pruner.previous_ecosystem = deepcopy(state.ecosystem)
    return modes_data
end

function update_pruner!(archiver::FSMArchiver, state::State)
    if state.generation == 1
        for learner in state.ecosystem.learner_population
            learner.tag = learner.id
        end

        for learner in state.ecosystem.learner_children
            learner.tag = learner.parent_id
        end
        archiver.pruner = ModesPruner(state)
        data = nothing
    #elseif state.generation % archiver.pruner.checkpoint_interval == 0
    elseif state.generation % 100 == 0
        data = update!(archiver.pruner, state)
    else 
        data = nothing
    end
    return data
end

function archive!(archiver::FSMArchiver, state::State)
    println("Generation = ", state.generation)
    println("Tags = ", [learner.tag for learner in state.ecosystem.learner_population])
    data = update_pruner!(archiver, state)
    if data === nothing
        return
    end
    
    # Define the fields to be archived
    info = (
        trial = state.configuration.id, 
        algorithm = state.configuration.test_algorithm,
        generation = state.generation, 
        subjective_fitness = data.utility_subjective,
        utility_16 = data.utility_16,
        utility_32 = data.utility_32,
        utility_64 = data.utility_64,
        utility_128 = data.utility_128,
        utility_all = data.utility_all,
        change = data.change,
        novelty = data.novelty,
        ecology = data.ecology,
        full_complexity = data.full_complexity,
        hopcroft_complexity = data.hopcroft_complexity,
        modes_complexity = data.modes_complexity,
        seed = state.configuration.seed
    )
    
    # Append the information to the archiver's data
    push!(archiver.data, info)
    
    # Save the updated data to a CSV file
    CSV.write(get_save_file(state.configuration), archiver.data)
end
