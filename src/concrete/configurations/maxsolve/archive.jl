export create_archivers, DensityClassificationArchiver, archive!

using DataFrames
using CSV
using Serialization
using ....Abstract

struct DensityClassificationArchiver <: Archiver end


using Random
using StatsBase
using ...Matrices.Outcome
using Serialization

import ....Interfaces: archive!

include("improved.jl")

function archive!(::DensityClassificationArchiver, state::State)
    #all_data = DataFrame()
    println("\n\n------------GENERATION $(state.generation)------------")
    println("reproduction_time = ", state.timers.reproduction_time)
    println("simulation_time = ", state.timers.simulation_time)
    println("evaluation_time = ", state.timers.evaluation_time)
    if state.generation > 1 && state.generation % 2 == 0
        println("---------")
        all_tests = [state.ecosystem.test_archive ; state.ecosystem.test_population ; state.ecosystem.test_children]
        all_tests = state.ecosystem.test_archive
        elite_fitness = -1
        elite_rule = nothing
        #for learner in [state.ecosystem.learner_population ; state.ecosystem.learner_children]
        for learner in state.ecosystem.learner_archive
            p = filter_columns(state.ecosystem.payoff_matrix,[test.id for test in all_tests])
            #p = state.ecosystem.payoff_matrix
            fitness = sum(p[learner.id, :])
            if fitness > elite_fitness
                elite_fitness = fitness
                elite_rule = learner
            end
        end
        #elite_rule = reduce((a, b) -> (a.id) < b.id ? a : b, state.ecosystem.learner_archive)
        #elite_fitness = sum(state.ecosystem.payoff_matrix[elite_rule.id, :])
        println("ELITE RULE ID = ", elite_rule.id)
        println("rule =", elite_rule.genotype.genes)
        println("FITNESS: ", elite_fitness, " out of ", length(state.ecosystem.payoff_matrix.column_ids))
        ics = [test.genotype.genes for test in all_tests]
        results = [covered_improved(elite_rule.genotype.genes, ic, 320) for ic in ics]
        println("REPLAYED_SCORE_VS_TESTS: ", sum(results), " out of ", length(results))
        #p = filter_rows(state.ecosystem.payoff_matrix, [elite_rule.id])
        #println(p)
        #elite_rule = first(state.ecosystem.learner_archive).genotype.genes
        ics = generate_unbiased_ICs(149, 2500)
        results = [covered_improved(elite_rule.genotype.genes, ic, 320) for ic in ics]
        println("\n#*****SCORE vs RANDOM*****\n: ", mean(results))
        flush(stdout)
        ms = sort(round.([mean(indiv.genotype.genes) for indiv in state.ecosystem.test_archive], digits = 3))
        println("average_test_genotype_val = ", ms)
        #all_tests = [state.ecosystem.test_archive ; state.ecosystem.test_population ; state.ecosystem.test_children]
        #f = Dict()
        #for test in all_tests
        #    ic = test.genotype.genes
        #    result = covered_improved(elite_rule.genotype.genes, ic, 320)
        #    f[test.id] = result
        #end
        #println(f)
        println("---------")
        #if elite_fitness != sum(results)
        #    serialize("state.jls", state)
        #    error("ELITE FOUND")
        #end
    end
end


#function create_archivers(::DensityClassificationExperimentConfiguration)
#    archivers = [DensityClassificationArchiver()]
#    return archivers
#end
