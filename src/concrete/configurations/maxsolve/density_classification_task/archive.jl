export create_archivers, DensityClassificationArchiver, archive!

using DataFrames
using CSV
using Serialization
using Distributed
using ....Abstract
using Random
using StatsBase
using ...Matrices.Outcome
using Serialization

import ....Interfaces: archive!



struct DensityClassificationArchiver <: Archiver 
    data::DataFrame
end

function DensityClassificationArchiver()
    if isfile("results.csv")
        data = CSV.read("results.csv", DataFrame)
    else
        data = DataFrame(
            trial = Int[], 
            algorithm = String[],
            generation = Int[], 
            fitness = Float64[], 
            score = Float64[], 
            seed = Int[]
        )
    end
    return DensityClassificationArchiver(data)
end


function get_elite_rule_and_fitness(::DensityClassificationArchiver, state::State)
    evaluation = first(state.evaluations)
    payoff_matrix = evaluation.payoff_matrix
    elite_fitness = -1
    elite_rule = nothing
    for learner in state.ecosystem.learners.active
        #p = state.ecosystem.payoff_matrix
        fitness = sum(payoff_matrix[learner.id, :])
        if fitness > elite_fitness
            elite_fitness = fitness
            elite_rule = learner
        end
    end
    return elite_rule, elite_fitness
end

function replay_tests(elite_rule::Individual, state::State)
    all_tests = [state.ecosystem.test_population ; state.ecosystem.test_children]
    ics = [test.genotype.genes for test in all_tests]
    results = [covered_improved(elite_rule.genotype.genes, ic, 320) for ic in ics]
    return results
end

function get_validation_score(
    elite_rule::Individual, 
    configuration::DensityClassificationTaskConfiguration
)
    ic_length = configuration.initial_condition_length
    n_ics = configuration.n_validation_initial_conditions
    n_timesteps = configuration.n_timesteps
    ics = generate_unbiased_ICs(ic_length, n_ics)
    #results = [covered_improved(elite_rule.genotype.genes, ic, n_timesteps) for ic in ics]
    results = pmap(ic -> covered_improved(elite_rule.genotype.genes, ic, n_timesteps), ics)
    score = mean(results)
    return score
end

function print_timers(state)
    trial = state.configuration.id
    println("\n\n------------GENERATION $(state.generation), TRIAL $trial------------")
    println("reproduction_time = ", state.timers.reproduction_time)
    println("simulation_time = ", state.timers.simulation_time)
    println("evaluation_time = ", state.timers.evaluation_time)
end

function get_average_genotype_values(individuals::Vector{<:Individual}; do_sort::Bool = false)
    values = round.([mean(indiv.genotype.genes) for indiv in individuals], digits = 3)
    values = do_sort ? sort(values) : values
    return values
end

function print_generation_info(
    elite_rule, elite_fitness, score, test_population_values, test_children_values
)
    println(
        "ELITE RULE ID = ", elite_rule.id, 
        ", FITNESS = ", elite_fitness, 
        ", VALIDATION_SCORE = ", score
    )
    println("RULE = ", elite_rule.genotype.genes)
    println("TEST_POP_VALUES = ", test_population_values)
    println("\nTEST_CHILDREN_VALUES = ", test_children_values)
    println("---------")
    flush(stdout)
end

function archive!(archiver::DensityClassificationArchiver, state::State)
    #all_data = DataFrame()
    #if state.generation > 1 && state.generation % 1 == 0
    elite_rule, elite_fitness = get_elite_rule_and_fitness(archiver, state)
    score = get_validation_score(elite_rule, state.configuration)
    test_population_values = get_average_genotype_values(state.ecosystem.tests.population)
    test_children_values = get_average_genotype_values(
        state.ecosystem.tests.children; do_sort = true
    )
            # Append the current results to the archiver's DataFrame
    info = (
        trial = state.configuration.id, 
        algorithm = state.configuration.algorithm,
        generation = state.generation, 
        fitness = elite_fitness,
        score = score,
        seed = state.configuration.seed
    )
    push!(archiver.data, info)

    # Optionally, save the DataFrame to a CSV file every generation
    CSV.write("results.csv", archiver.data)
    print_generation_info(
        elite_rule, elite_fitness, score, test_population_values, test_children_values
    )
    #end
end

function create_archivers(config::DensityClassificationTaskConfiguration)
    archivers = [DensityClassificationArchiver()]
    return archivers
end


#function create_archivers(::DensityClassificationExperimentConfiguration)
#    archivers = [DensityClassificationArchiver()]
#    return archivers
#end
