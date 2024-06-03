export prune_species, merge_dicts, safe_median, get_node_medians

using StatsBase: median
using ....Abstract
using ....Interfaces
using ...Individuals.Modes: ModesIndividual
using ...Ecosystems.Simple: SimpleEcosystem
using ...Genotypes.FunctionGraphs: substitute_node_with_bias_connection
using ...Species.Basic: BasicSpecies
using ...Performers.Basic: BasicPerformer
using ...Simulators.Basic: BasicSimulator

mutable struct PruneJob
    node_id::Int
    to_substitute_value::Float32
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

function merge_dicts(dicts::Vector{Dict{Int, Vector{Float32}}})
    merged = Dict{Int, Vector{Float32}}()
    for dict in dicts
        for (key, value) in dict
            merged_value = get!(merged, key, Vector{Float32}())
            append!(merged_value, value)
        end
    end
    return merged
end

function get_node_medians(individual::Individual, observations::Vector{<:Observation})
    node_states_accumulator = Dict{Int, Vector{Float32}}()

    for observation in observations
        if individual.id in keys(observation.all_phenotype_states)
            for (node_id, states) in observation.all_phenotype_states[individual.id]
                append!(get!(node_states_accumulator, node_id, Vector{Float32}()), states)
            end
        end
    end

    node_medians = Dict{Int, Float32}(
        node_id => safe_median(states) for (node_id, states) in node_states_accumulator
    )

    return node_medians
end

# Create PruneJobs for a given individual
function create_prune_jobs(individual::Individual, node_medians::Dict{Int, Float32})
    prune_jobs = [
        PruneJob(node.id, node_medians[node.id]) 
        for node in individual.minimized_genotype.hidden_nodes
    ]
    return prune_jobs
end

function get_hidden_node_ids(individual::Individual)
    # Assuming `hidden_nodes` is a property of the genotype that lists hidden node IDs
    return [node.id for node in individual.minimizd_genotype.hidden_nodes]
end

function create_candidate(individual::ModesIndividual, job::PruneJob, state::State)
    genotype = substitute_node_with_bias_connection(
        individual.minimized_genotype, job.node_id, job.to_substitute_value
    )
    individual = ModesIndividual(
        id = individual.id,
        parent_id = individual.parent_id,
        tag = individual.tag,
        full_genotype = individual.full_genotype,
        minimized_genotype = minimize(genotype),
        phenotype = create_phenotype(state.reproducer.phenotype_creator, individual.id, genotype)
    )
    return individual
end

function create_modes_simulator(individual::ModesIndividual, state::State)
    simulator = BasicSimulator(
        interactions = state.simulator.interactions,
        matchmaker = state.simulator.matchmaker,
        job_creator = state.simulator.job_creator,
        performer = BasicPerformer(state.simulator.performer.n_workers),
    )
    for interaction in simulator.interactions
        interaction.observer.is_active = true
        interaction.observer.ids_to_observe = [individual.id]
    end
    return simulator
end

using Serialization

function get_node_medians_and_fitness(
    species::BasicSpecies, individual::ModesIndividual, opponents::BasicSpecies, state::State
)
    simulator = create_modes_simulator(individual, state)
    ecosystem = SimpleEcosystem(1, [BasicSpecies(species.id, [individual]), opponents])
    try
        results = simulate(simulator, ecosystem, state )
        observations = [result.observation for result in results]
        node_medians = get_node_medians(individual, observations)
        evaluation = first(evaluate(ScalarFitnessEvaluator(), ecosystem, results, state))
        fitness = first(filter(x -> x.id == individual.id, evaluation.records)).scaled_fitness
        return node_medians, fitness
    catch e
        simulator_file = open("test/circle/simulator.jls", "w")
        serialize(simulator_file, simulator)
        close(simulator_file)
        ecosystem_file = open("test/circle/ecosystem.jls", "w")
        serialize(ecosystem_file, ecosystem)
        close(ecosystem_file)
        throw(e)
    end

end

function update_prune_jobs!(prune_jobs::Vector{PruneJob}, node_medians::Dict{Int, Float32})
    for job in prune_jobs
        if haskey(node_medians, job.node_id)
            job.to_substitute_value = node_medians[job.node_id]
        end
    end
end

function print_summaries(species::BasicSpecies, fitnesses::Dict{Int, Float64}, tag::String)
    summaries = [
        (
            individual.id, 
            get_size(individual.minimized_genotype), 
            round(fitnesses[individual.id]; digits = 3)
        ) 
        for individual in species.population
    ]
    sort!(summaries, by = x -> x[3]; rev = true)
    println("$(species.id)_$tag = ", summaries)
end

using Serialization

function prune_species(modes::BasicSpecies, opponents::BasicSpecies, state::State)
    I = typeof(first(modes.population))
    fully_pruned_individuals = I[]
    original_fitnesses = Dict{Int, Float64}()
    pruned_fitnesses = Dict{Int, Float64}()
    
    for current_individual in modes.population
        try
            node_medians, current_fitness = get_node_medians_and_fitness(modes, current_individual, opponents, state)
            original_fitnesses[current_individual.id] = current_fitness
            prune_jobs = create_prune_jobs(current_individual, node_medians)
            for job in prune_jobs
                # Perform pruning for the current node
                try
                    candidate = create_candidate(current_individual, job, state)
                    node_medians, candidate_fitness = get_node_medians_and_fitness(
                        modes, candidate, opponents, state
                    )

                    if current_fitness == candidate_fitness
                        update_prune_jobs!(prune_jobs, node_medians)
                        current_individual = candidate
                    end
                catch e
                    println("Error in pruning: ", e)
                    println("current_individual = ", current_individual)
                    println("candidate = ", candidate)
                    println("job = ", job)
                    throw(e)
                end
            end
            push!(fully_pruned_individuals, current_individual)
            pruned_fitnesses[current_individual.id] = current_fitness
        catch e
            println("Error in initialization: ", e)
            println("current_individual = ", current_individual)
            throw(e)
        end
    end
    pruned_species = BasicSpecies(modes.id, fully_pruned_individuals)
    print_summaries(modes, original_fitnesses, "original")
    print_summaries(pruned_species, pruned_fitnesses, "pruned")

    return pruned_species
end
