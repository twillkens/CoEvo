using CoEvo
using CoEvo.Names
using CoEvo.Configurations.PredictionGame
using CoEvo.Genotypes.FunctionGraphs
using Test
using Random

include("equals.jl")

include("observer.jl")

include("individual.jl")

include("species.jl")

include("matchmaker.jl")

include("prune.jl")

include("evaluation.jl")

include("simulate_2.jl")

include("reporter.jl")

function run_test()
    ecosystem_creator = make_ecosystem_creator(
        make_prediction_game_experiment(
            topology = "two_competitive", 
            report = "silent", 
            n_population = 50, 
            n_children = 50,
            n_workers = 1,
            seed = 777,
            n_nodes_per_output = 1,
        )
    )
    ecosystem = create_ecosystem(ecosystem_creator)

    reporter = ModesReporter(modes_interval = 50)
    for i in 1:10_000
        report = create_report(
            reporter, 
            1,
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