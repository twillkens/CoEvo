export create_archivers, DensityClassificationArchiver, archive!

using DataFrames
using CSV
using Serialization
using ....Abstract
using Distributed
using ...Domains.DensityClassification: covered_improved
using Random
using StatsBase
using ...Matrices.Outcome
using Serialization

import ....Interfaces: archive!


struct DensityClassificationArchiver <: Archiver 
    data::DataFrame
end

function get_dct_save_file(configuration::QueMEUConfiguration)
    task = configuration.task
    algo = configuration.test_algorithm
    domain = configuration.domain
    tag = configuration.tag
    file = "$(task)-$(algo)-$(domain)-$(tag).csv"
    return file
end

function DensityClassificationArchiver(configuration::QueMEUConfiguration)
    file = get_dct_save_file(configuration)
    if isfile(file)
        data = CSV.read(file, DataFrame)
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

function generate_unbiased_ICs(n::Int, n_samples::Int)
    # Initialize an array to hold the generated ICs
    ICs = Vector{Vector{Int}}(undef, n_samples)

    # Generate each IC
    for i in 1:n_samples
        # For an unbiased distribution, each bit has a 50% chance of being 1 or 0
        IC = rand(0:1, n)
        ICs[i] = IC
    end

    return ICs
end

function archive!(archiver::DensityClassificationArchiver, state::State)
    #all_data = DataFrame()
    println("\n\n------------GENERATION $(state.generation), $SAVE_FILE------------")
    println("reproduction_time = ", state.timers.reproduction_time)
    println("simulation_time = ", state.timers.simulation_time)
    println("evaluation_time = ", state.timers.evaluation_time)
    if state.generation > 1 && state.generation % 1 == 0
        println("---------")
        all_tests = [state.ecosystem.test_population ; state.ecosystem.test_children]
        elite_fitness = -1
        elite_rule = nothing
        for learner in [state.ecosystem.learner_population ; state.ecosystem.learner_children]
            p = filter_columns(state.ecosystem.payoff_matrix, [test.id for test in all_tests])
            #p = state.ecosystem.payoff_matrix
            fitness = sum(p[learner.id, :])
            if fitness > elite_fitness
                elite_fitness = fitness
                elite_rule = learner
            end
        end
        println("ELITE RULE ID = ", elite_rule.id)
        println("rule =", elite_rule.genotype.genes)
        println("FITNESS: ", elite_fitness, " out of ", length(all_tests))
        ics = [test.genotype.genes for test in all_tests]
	    results = pmap(ic -> covered_improved(elite_rule.genotype.genes, ic, 320), ics)
        println("REPLAYED_SCORE_VS_TESTS: ", sum(results), " out of ", length(results))
        ics = generate_unbiased_ICs(149, 10_000)
	    results = pmap(ic -> covered_improved(elite_rule.genotype.genes, ic, 320), ics)
        score = mean(results)
        println("\n#*****SCORE vs RANDOM*****\n\n", score)
        println()

        ms = round.([mean(indiv.genotype.genes) for indiv in state.ecosystem.test_population], digits = 3)
	    println("average_pop_test_genotype_val = ", reverse(ms))
        ms = sort(round.([mean(indiv.genotype.genes) for indiv in state.ecosystem.test_children], digits = 3))
        println("\naverage_children_test_genotype_val = ", ms)
        flush(stdout)
        println("---------")
        info = (
            trial = state.configuration.id, 
            algorithm = state.configuration.test_algorithm,
            generation = state.generation, 
            fitness = elite_fitness,
            score = score,
            seed = state.configuration.seed
        )
        push!(archiver.data, info)
    
        file = get_dct_save_file(state.configuration)
        # Optionally, save the DataFrame to a CSV file every generation
        CSV.write(file, archiver.data)
    end
end
