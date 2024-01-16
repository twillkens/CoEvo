export PruneIndividual, prune_species, merge_dicts, safe_median, get_node_medians
export update_individual!, print_min_summaries, print_prune_summaries

using StatsBase: median
using ....Abstract
using ....Interfaces
using ...Phenotypes.FunctionGraphs: FunctionGraphPhenotype
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: substitute_node_with_bias_connection
using ...Individuals.Modes: ModesIndividual
using ...Ecosystems.Simple: SimpleEcosystem
using ...Species.Basic: BasicSpecies

Base.@kwdef mutable struct PruneIndividual{G <: Genotype, P <: Phenotype} <: Individual
    id::Int
    full_genotype::G
    full_fitness::Float64
    genes_to_check::Vector{Int}
    current_genotype::G
    current_fitness::Float64
    current_node_medians::Dict{Int, Float32}
    candidate_genotype::G
    phenotype::P
end

function PruneIndividual(
    individual::ModesIndividual, 
    observations::Vector{<:Observation}, 
    evaluation::Evaluation,
    state::State
)
   current_fitness = first(filter(x -> x.id == individual.id, evaluation.records)).scaled_fitness
   current_node_medians = get_node_medians(individual, observations)
    if get_size(individual.minimized_genotype) == 0
        return PruneIndividual(
            id = individual.id,
            full_genotype = individual.full_genotype,
            full_fitness = current_fitness,
            current_genotype = individual.minimized_genotype,
            current_fitness = current_fitness,
            current_node_medians = current_node_medians,
            candidate_genotype = individual.minimized_genotype,
            genes_to_check = Int[],
            phenotype = individual.phenotype,
        )
    else
        genes_to_check = [node.id for node in individual.minimized_genotype.hidden_nodes]
        gene_to_check = popfirst!(genes_to_check)
        candidate_genotype = substitute_node_with_bias_connection(
            individual.current_genotype, gene_to_check, current_node_medians[gene_to_check]
        )
        phenotype = create_phenotype(
            state.reproducer.phenotype_creator, 
            individual.id,
            candidate_genotype
        )
        return PruneIndividual(
            id = individual.id,
            full_genotype = individual.full_genotype,
            full_fitness = current_fitness,
            genes_to_check = genes_to_check,
            current_genotype = individual.minimized_genotype,
            current_fitness = current_fitness,
            current_node_medians = current_node_medians,
            candidate_genotype = candidate_genotype,
            phenotype = phenotype,
        )
    end
end

function merge_dicts(dicts::Vector{Dict{Int, Vector{Float32}}})
    merged = Dict{Int, Vector{Float32}}()
    for dict in dicts
        for (key, value) in dict
            if haskey(merged, key)
                append!(merged[key], value)
            else
                merged[key] = value
            end
        end
    end

    return merged
end

function safe_median(values::Vector{Float32})
    median_value = median(values)
    if isinf(median_value)
        median_value = median_value > 0 ? prevfloat(Inf32) : nextfloat(-Inf32)
    elseif isnan(median_value)
        error("NaN median value")
    end
    return median_value
end

function get_node_medians(individual::Individual, observations::Vector{<:Observation})
    individual_state_dicts = [
        observation.all_phenotype_states[individual.id] 
        for observation in observations 
            if individual.id in keys(observation.all_phenotype_states)
    ]
    node_states = merge_dicts(individual_state_dicts)
    node_medians = Dict(
        node_id => safe_median(node_states[node_id]) 
        for node_id in keys(node_states)
    )
    return node_medians
end

function update_individual!(
    individual::PruneIndividual, 
    observations::Vector{<:Observation}, 
    evaluation::Evaluation,
    state::State
)
   candidate_fitness = first(filter(x -> x.id == individual.id, evaluation.records)).scaled_fitness
   candidite_node_medians = get_node_medians(individual, observations)
   if candidate_fitness >= individual.current_fitness
       individual.current_genotype = individual.candidate_genotype
       individual.current_fitness = candidate_fitness
       individual.current_node_medians = candidite_node_medians
   end
    if get_size(individual.current_genotype) == 0 || length(individual.genes_to_check) == 0
        return individual
    end
    gene_to_check = popfirst!(individual.genes_to_check)
    candidate_genotype = substitute_node_with_bias_connection(
        individual.current_genotype, 
        gene_to_check, 
        individual.current_node_medians[gene_to_check]
    )
    phenotype = create_phenotype(
        state.reproducer.phenotype_creator, 
        individual.id,
        candidate_genotype
    )
    individual.candidate_genotype = candidate_genotype
    individual.phenotype = phenotype
end


function print_min_summaries(species_id::String, new_modes_pruned::Vector{<:PruneIndividual})
    ids = [individual.id for individual in new_modes_pruned]
    sizes = [get_size(individual.full_genotype) for individual in new_modes_pruned]
    fitnesses = [round(individual.full_fitness, digits = 3) for individual in new_modes_pruned]
    summaries = [
        (id, size, fitness) 
        for (id, size, fitness) in zip(ids, sizes, fitnesses)
    ]
    println("$(species_id)_min = $summaries")
end

function print_prune_summaries(species_id::String, new_pruned::Vector{<:PruneIndividual})
    ids = [individual.id for individual in new_pruned]
    sizes = [get_size(individual.current_genotype) for individual in new_pruned]
    fitnesses = [individual.current_fitness for individual in new_pruned]
    summaries = [
        (id, size, round(fitness; digits = 3)) 
        for (id, size, fitness) in zip(ids, sizes, fitnesses)
    ]
    sort!(summaries, by = x -> x[3]; rev = true)
    println("$(species_id)_prune = ", summaries)
end

function prune_species(modes::BasicSpecies, opponents::BasicSpecies, state::State)
    ecosystem = SimpleEcosystem(1, [modes, opponents])

    for interaction in state.simulator.interactions
        interaction.observer.is_active = true
    end
    results = simulate(state.simulator, ecosystem, state )
    observations = [result.observation for result in results]
    evaluation = first(evaluate(ScalarFitnessEvaluator(), ecosystem, results, state))

    prune_individuals = [
        PruneIndividual(individual, observations, evaluation, state) 
        for individual in modes.population
    ]
    I = typeof(prune_individuals[1])
    to_prune = I[]
    fully_pruned = I[]
    for individual in prune_individuals
        if length(individual.genes_to_check) == 0
            push!(fully_pruned, individual)
        else
            push!(to_prune, individual)
        end
    end
    max_iterations = 1000
    current_iteration = 0

    while length(to_prune) > 0
        current_iteration += 1
        if current_iteration > max_iterations
            println("to_prune = ", to_prune)
            println("fully_pruned = ", fully_pruned)
            error("Max iterations exceeded")
        end
        ecosystem = SimpleEcosystem(1, [to_prune, opponents])
        results = simulate(state.simulator, ecosystem, state )
        observations = [result.observation for result in results]
        evaluation = first(evaluate(ScalarFitnessEvaluator(), ecosystem, results, state))
        for individual in to_prune
            update_individual!(individual, observations, evaluation, state)
            if length(individual.genes_to_check) == 0
                push!(fully_pruned, individual)
                filter!(x -> x.id != individual.id, to_prune)
            end
        end
    end
    print_min_summaries(modes.id, fully_pruned)
    print_prune_summaries(modes.id, fully_pruned)
    return [individual.current_genotype for individual in fully_pruned]
end

