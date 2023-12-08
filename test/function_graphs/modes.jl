using CoEvo
using CoEvo.Names
using CoEvo.Configurations.PredictionGame
using CoEvo.Genotypes.FunctionGraphs
using Test
using Random

Base.@kwdef mutable struct ModesReporter{S <: AbstractSpecies} <: Reporter
    modes_interval::Int = 10
    tag_dictionary::Dict{Int, Int} = Dict{Int, Int}()
    persistent_ids::Set{Int} = Set{Int}()
    all_species::Vector{S} = AbstractSpecies[]
end

function update_species_list(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    reporter.all_species = copy(all_species)
end

function reset_tag_dictionary(reporter::ModesReporter)
    empty!(reporter.tag_dictionary)
end

function update_tag_dictionary(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    individuals = vcat([get_individuals(species) for species in all_species]...)
    for (tag, individual) in enumerate(individuals)
        reporter.tag_dictionary[individual.id] = tag
    end
end

function update_persistent_ids(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    persistent_tags = Set{Int}()
    individuals = vcat([get_individuals(species) for species in all_species]...)
    for individual in individuals
        parent_id = first(individual.parent_ids)
        if haskey(reporter.tag_dictionary, parent_id)
            tag = reporter.tag_dictionary[parent_id]
            push!(persistent_tags, tag)
            reporter.tag_dictionary[individual.id] = tag
        end
    end
    empty!(reporter.persistent_ids)
    all_individuals = vcat([get_individuals(species) for species in reporter.all_species]...)
    for individual in all_individuals
        tag = reporter.tag_dictionary[individual.id]
        if tag in persistent_tags
            push!(reporter.persistent_ids, individual.id)
        end
    end
end

function get_all_ids(all_species::Vector{<:AbstractSpecies})
    all_individuals = vcat([get_individuals(species) for species in all_species]...)
    all_ids = Set(individual.id for individual in all_individuals)
    return all_ids
end

mutable struct ModesIndividual{G <: Genotype} <: Individual
    id::Int
    genotype::G
    genes_to_check::Vector{Int}
    observations::Vector{<:Observation}
    fitness::Float64
end

function ModesIndividual(id::Int, genotype::Genotype)
    genes_to_check = get_genes_to_check(genotype)
    observations = Observation[]
    fitness = -Inf
    individual = ModesIndividual(id, genotype, genes_to_check, observations, fitness)
    return individual
end

function is_fully_pruned(individual::ModesIndividual)
    return length(individual.genes_to_check) == 0
end

function get_maximum_complexity(genotypes::Vector{<:Genotype})
    maximum_complexity = maximum(get_size(genotype) for genotype in genotypes)
    return maximum_complexity
end

function get_maximum_complexity(individuals::Vector{<:ModesIndividual})
    return get_maximum_complexity([individual.genotype for individual in individuals])
end

import CoEvo.Individuals: get_individuals

struct ModesSpecies{I <: BasicIndividual, M <: ModesIndividual} <: AbstractSpecies
    id::String
    normal_individuals::Vector{I}
    modes_individuals::Vector{M}
end

function is_fully_pruned(species::ModesSpecies)
    return length(species.modes_individuals) == 0
end

function is_fully_pruned(all_species::Vector{<:ModesSpecies})
    return all(is_fully_pruned, all_species)
end

function get_maximum_complexity(species::ModesSpecies)
    maximum_complexity = get_maximum_complexity(species.modes_individuals)
    return maximum_complexity
end

function get_maximum_complexity(all_species::Vector{<:ModesSpecies})
    maximum_complexity = maximum([get_maximum_complexity(species) for species in all_species])
    return maximum_complexity
end

function get_individuals(species::ModesSpecies)
    all_individuals = [species.normal_individuals ; species.modes_individuals]
    return all_individuals
end

function get_genes_to_check(genotype::FunctionGraphGenotype)
    gene_ids = sort(genotype.hidden_node_ids, rev = true)
    return gene_ids
end

function ModesSpecies(
    species::BasicSpecies{BasicIndividual{G}}, persistent_ids::Set{Int}
) where {G <: Genotype}
    normal_individuals = get_individuals(species)
    modes_individuals = ModesIndividual{G}[]
    for individual in normal_individuals
        if individual.id in persistent_ids
            genotype = minimize(individual.genotype)
            # println("chosen: ", individual.id, ", from ", persistent_ids, ", with size: ", get_size(genotype))
            modes_individual = ModesIndividual(-individual.id, genotype)
            push!(modes_individuals, modes_individual)
        end
    end
    #println(modes_individuals)
    modes_species = ModesSpecies(species.id, normal_individuals, modes_individuals)
    return modes_species
end

import CoEvo.MatchMakers: make_matches
using CoEvo.Matches.Basic: BasicMatch

function make_matches(
    ::AllVersusAllMatchMaker, 
    interaction_id::String, 
    species_1::ModesSpecies, 
    species_2::ModesSpecies
)
    modes_ids_1 = [individual.id for individual in species_1.modes_individuals ]
    normal_ids_2 = [individual.id for individual in species_2.normal_individuals]
    match_ids_1 = vec(collect(Iterators.product(modes_ids_1, normal_ids_2)))
    matches_1 = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids_1]  

    normal_ids_1 = [individual.id for individual in species_1.normal_individuals]
    modes_ids_2 = [individual.id for individual in species_2.modes_individuals]
    match_ids_2 = vec(collect(Iterators.product(normal_ids_1, modes_ids_2)))
    matches_2 = [BasicMatch(interaction_id, [id_1, id_2]) for (id_1, id_2) in match_ids_2]

    matches = vcat(matches_1, matches_2)
    #println("matches: $matches")
    return matches
end

import CoEvo.Observers: observe!, create_observation

Base.@kwdef mutable struct FunctionGraphModesObserver <: Observer 
    to_observe_id::Int = 0
    other_id::Int = 0
    node_states::Dict{Int, Vector{Float32}} = Dict{Int, Vector{Float32}}()
end

function observe!(
    observer::FunctionGraphModesObserver, phenotype::LinearizedFunctionGraphPhenotype
)
        # For each node in the phenotype, append its current value to the appropriate vector
    # if phenotype.id == -12609
    #     println(phenotype)
    # end
    for node in phenotype.nodes
        # Create a vector for this node's id if not already present
        if !haskey(observer.node_states, node.id)
            observer.node_states[node.id] = Float32[]
        end
        push!(observer.node_states[node.id], node.current_value)
    end
end

function observe!(
    observer::FunctionGraphModesObserver, environment::ContinuousPredictionGameEnvironment
)
    if environment.entity_1.id < 0
        observer.to_observe_id = environment.entity_1.id
        observer.other_id = environment.entity_2.id
        observe!(observer, environment.entity_1)
    elseif environment.entity_2.id < 0
        observer.to_observe_id = environment.entity_2.id
        observer.other_id = environment.entity_1.id
        observe!(observer, environment.entity_2)
    else
        throw(ErrorException("Neither entity has a negative id for FunctionGraphModesObserver."))
    end
end

struct FunctionGraphModesObservation <: Observation
    id::Int
    other_id::Int
    node_states::Dict{Int, Vector{Float32}}
end

function create_observation(observer::FunctionGraphModesObserver)
    observation = FunctionGraphModesObservation(
        observer.to_observe_id,
        observer.other_id,
        observer.node_states
    )
    observer.to_observe_id = 0
    observer.other_id = 0
    observer.node_states = Dict{Int, Vector{Float32}}()
    return observation
end

function get_scalar_fitness_evaluators(species_creators::Vector{<:SpeciesCreator})
    evaluators = [species_creator.evaluator for species_creator in species_creators]
    evaluators = map(evaluators) do evaluator
        if typeof(evaluator) === ScalarFitnessEvaluator
            return evaluator
        elseif typeof(evaluator) === NSGAIIEvaluator
            return evaluator.scalar_fitness_evaluator
        else
            throw(ErrorException("Evaluator type $(typeof(evaluator)) not supported for MODES."))
        end
    end
    return evaluators
end

function get_phenotype_creators(species_creators::Vector{<:SpeciesCreator})
    phenotype_creators = [
        species_creator.phenotype_creator for species_creator in species_creators
    ]
    return phenotype_creators
end


function get_gene_median_dict(observations::Vector{FunctionGraphModesObservation})
    all_gene_output_dict = Dict{Int, Vector{Float32}}()
    for observation in observations
        for (id, node_states) in observation.node_states
            if !haskey(all_gene_output_dict, id)
                all_gene_output_dict[id] = Float32[]
            end
            push!(all_gene_output_dict[id], node_states...)
        end
    end
    gene_median_dict = Dict(
        id => median(all_gene_output_dict[id]) for id in keys(all_gene_output_dict)
    )
    return gene_median_dict
end

using StatsBase: median
# Function to remove a subtree and redirect connections
function remove_node_and_redirect(
    genotype::FunctionGraphGenotype, 
    to_prune_node_id::Int, 
    bias_node_id::Int, 
    new_weight::Float64,
)
    genotype = deepcopy(genotype)
    # Redirect connections
    for (id, node) in genotype.nodes
        if id == to_prune_node_id
            continue
        end

        new_input_connections = FunctionGraphConnection[]
        for connection in node.input_connections
            if connection.input_node_id == to_prune_node_id
                push!(new_input_connections, FunctionGraphConnection(
                    input_node_id = bias_node_id, 
                    weight = new_weight, 
                    is_recurrent = false
                ))
            else
                push!(new_input_connections, connection)
            end
        end
        genotype.nodes[id] = FunctionGraphNode(id, node.func, new_input_connections)
    end

    # Remove the nodes in the subtree
    delete!(genotype.nodes, to_prune_node_id)
    filter!(x -> x != to_prune_node_id, genotype.hidden_node_ids)

    return genotype
end
# Prune a single node and return the updated genotype, error, and observation
function modes_prune(genotype::FunctionGraphGenotype, node_id::Int, weight::Real)
    bias_node_id = first(genotype.bias_node_ids)
    pruned_genotype = remove_node_and_redirect(genotype, node_id, bias_node_id, Float64(weight))
    pruned_genotype = minimize(pruned_genotype)
    return pruned_genotype
end



function get_scaled_fitness(evaluation::ScalarFitnessEvaluation, id::Int)
    record = first(filter(record -> record.id == id, evaluation.records))
    return record.scaled_fitness
end

function get_scaled_fitness(evaluations::Vector{<:ScalarFitnessEvaluation}, id::Int)
    for evaluation in evaluations
        for record in evaluation.records
            if record.id == id
                return record.scaled_fitness
            end
        end
    end
    throw(ErrorException("Could not find id $id in evaluations."))
end


import CoEvo.Results: get_observations

function get_observations(observations::Vector{<:Observation}, id::Int)
    observations = filter(observation -> observation.id == id, observations)
    return observations
end

function get_gene_median_dict(individual::ModesIndividual)
    gene_median_dict = get_gene_median_dict(individual.observations)
    return gene_median_dict
end

function perform_modes_simulation!(
    all_species::Vector{<:ModesSpecies},
    species_creators::Vector{<:SpeciesCreator}, 
    job_creator::JobCreator, 
    performer::Performer, 
    random_number_generator::AbstractRNG,
)
    phenotype_creators = get_phenotype_creators(species_creators)
    evaluators = get_scalar_fitness_evaluators(species_creators)
    interactions = map(job_creator.interactions) do interaction
        BasicInteraction(interaction, [FunctionGraphModesObserver()])
    end
    job_creator = BasicJobCreator(interactions, job_creator.n_workers)
    jobs = create_jobs(
        job_creator, random_number_generator, all_species, phenotype_creators
    )
    results = perform(performer, jobs)
    outcomes = get_individual_outcomes(results)
    observations = get_observations(results)
    evaluations = evaluate(evaluators, random_number_generator, all_species, outcomes)
    for species in all_species
        for modes_individual in species.modes_individuals
            modes_individual.fitness = get_scaled_fitness(evaluations, modes_individual.id)
            modes_individual.observations = get_observations(observations, modes_individual.id)
        end
    end
end

function modes_prune!(individual::ModesIndividual)
    gene_median_dict = get_gene_median_dict(individual)
    gene_to_check = popfirst!(individual.genes_to_check)
    gene_median_value = gene_median_dict[gene_to_check]
    pruned_genotype = modes_prune(
        individual.genotype, gene_to_check, gene_median_value
    )
    pruned_individual = ModesIndividual(individual.id, pruned_genotype)
    return pruned_individual
end

function get_modes_results(
    species_creators::Vector{<:SpeciesCreator}, 
    job_creator::JobCreator,
    performer::Performer,
    rng::AbstractRNG,
    all_species::Vector{<:AbstractSpecies},
    persistent_ids::Set{Int}, 
)
    all_modes_species = [ModesSpecies(species, persistent_ids) for species in all_species]
    pruned_individuals = ModesIndividual[]
    for species in all_modes_species
        pruned_ids = Set{Int}()
        for modes_individual in species.modes_individuals
            if is_fully_pruned(modes_individual)
                push!(pruned_individuals, modes_individual)
                push!(pruned_ids, modes_individual.id)
            end
        end
        filter!(individual -> individual.id ∉ pruned_ids, species.modes_individuals)
    end
    if is_fully_pruned(all_modes_species)
        if length(pruned_individuals) == 0
            modes_individuals = [
                species.modes_individuals 
                for species in all_modes_species 
            ]
            println("all_modes_individuals: $modes_individuals")
            throw(ErrorException("All individuals are fully pruned but none were stored."))
        end
        return pruned_individuals
    end
    counter = 0
    perform_modes_simulation!(all_modes_species, species_creators, job_creator, performer, rng)
    while !is_fully_pruned(all_modes_species)
        all_next_modes_species = map(all_modes_species) do species
            next_individuals = map(species.modes_individuals) do modes_individual
                next_individual = modes_prune!(modes_individual)
                return next_individual
            end
            next_species = ModesSpecies(species.id, species.normal_individuals, next_individuals)
            return next_species
        end
        counter += 1
        perform_modes_simulation!(
            all_next_modes_species, species_creators, job_creator, performer, rng
        )
        for (modes_species, next_modes_species) in zip(all_modes_species, all_next_modes_species)
            pruned_ids = Set{Int}()
            for i in eachindex(modes_species.modes_individuals)
                modes_individual = modes_species.modes_individuals[i]
                next_modes_individual = next_modes_species.modes_individuals[i]
                if modes_individual.fitness <= next_modes_individual.fitness
                    if is_fully_pruned(next_modes_individual)
                        push!(pruned_individuals, next_modes_individual)
                        push!(pruned_ids, next_modes_individual.id)
                    else
                        modes_species.modes_individuals[i] = next_modes_individual
                    end
                elseif is_fully_pruned(modes_individual)
                    push!(pruned_individuals, modes_individual)
                    push!(pruned_ids, modes_individual.id)
                end
            end
            filter!(individual -> individual.id ∉ pruned_ids, modes_species.modes_individuals)
        end
    end
    return pruned_individuals
end

function create_report(
    reporter::ModesReporter, 
    generation::Int, 
    species_creators::Vector{<:SpeciesCreator},
    job_creator::JobCreator,
    performer::Performer,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AbstractSpecies}
)
    if generation == 1
        update_species_list(reporter, all_species)
        reset_tag_dictionary(reporter)
        update_tag_dictionary(reporter, all_species)
        reporter.persistent_ids = get_all_ids(all_species)
    elseif generation % reporter.modes_interval == 0
        pruned_individuals = get_modes_results(
            species_creators, 
            job_creator,
            performer,
            random_number_generator,
            reporter.all_species,
            reporter.persistent_ids
        )
        println("GENERATION: $generation, COMPLEXITY: ", get_maximum_complexity(pruned_individuals))
        update_species_list(reporter, all_species)
        reset_tag_dictionary(reporter)
        update_tag_dictionary(reporter, all_species)
        reporter.persistent_ids = get_all_ids(all_species)
    else
        update_persistent_ids(reporter, all_species)
    end
    return reporter.persistent_ids
end

function run_test()
    ecosystem_creator = make_ecosystem_creator(
        make_prediction_game_experiment(
            topology = "two_competitive", 
            report = "silent", 
            n_population = 50, 
            n_children = 50,
            n_workers = 1,
            seed = 42
        )
    )
    ecosystem = create_ecosystem(ecosystem_creator)

    reporter = ModesReporter(modes_interval = 50)
    for i in 1:10_000
        report = create_report(
            reporter, 
            i,
            ecosystem_creator.species_creators,
            ecosystem_creator.job_creator,
            ecosystem_creator.performer,
            ecosystem_creator.random_number_generator,
            ecosystem.species
        )
        #println(i, " ", report, ", ten should be max")
        ecosystem = evolve!(ecosystem_creator, ecosystem, i:i)
    end
end

run_test()