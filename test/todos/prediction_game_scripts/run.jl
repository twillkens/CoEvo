using Distributed
using ArgParse

function parse_cmdline_args()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--game"
            arg_type = String
            default = "continuous_prediction_game"
            help = "Game type"
        "--topology"
            arg_type = String
            default = "two_competitive"
            help = "Ecosystem topology"
        "--substrate"
            arg_type = String
            default = "function_graphs"
            help = "Substrate type"
        "--reproduction"
            arg_type = String
            default = "disco"
            help = "Reproduction method"
        "--report"
            arg_type = String
            default = "verbose_test"
            help = "Report type"
        "--n_trials" 
            arg_type = Int
            default = 1
            help = "Number of trials"
        "--trial"
            arg_type = Int
            default = 1
            help = "Trial ID"
        "--seed"
            arg_type = Int
            default = abs(rand(Int))
            help = "Seed value for RNG"
        "--n_workers"
            arg_type = Int
            default = 1
            help = "Number of workers"
        "--n_generations"
            arg_type = Int
            default = 20000
            help = "Number of generations"
        "--n_population"
            arg_type = Int
            default = 50
            help = "Population size"
        "--n_children"
            arg_type = Int
            default = 50
            help = "Number of children"
        "--communication_dimension"
            arg_type = Int
            default = 0
            help = "Communication dimension"
        "--episode_length"
            arg_type = Int
            default = 16
            help = "Episode length"
        "--n_nodes_per_output"
            arg_type = Int
            default = 1
            help = "Number of nodes per output"
        "--archive_interval"
            arg_type = Int
            default = 50
            help = "Archive interval"
        "--function_set"
            arg_type = String
            default = "all"
            help = "Function set"
        "--mutation"
            arg_type = String
            default = "shrink_volatile"
            help = "Mutation type"
        "--noise_std"
            arg_type = String
            default = "high"
            help = "Noise standard deviation"
        "--n_elites"
            arg_type = Int
            default = 0
            help = "Elites archive length"
    end

    return parse_args(s)
end

args = parse_cmdline_args()

# Add workers for this trial
if args["n_workers"] > 1
    addprocs(args["n_workers"])
end

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using CoEvo
    using CoEvo.NewConfigurations.ExperimentConfigurations.PredictionGame: PredictionGameExperimentConfiguration    
    using CoEvo.States.Evolutionary: evolve!
    using StableRNGs: StableRNG
end

config = PredictionGameExperimentConfiguration(;
    game = args["game"],
    topology = args["topology"],
    substrate = args["substrate"],
    reproduction = args["reproduction"],
    n_trials = args["n_trials"],
    trial = args["trial"],
    seed = args["seed"],
    n_workers = args["n_workers"],
    n_generations = args["n_generations"],
    archive_interval = args["archive_interval"],
    n_population = args["n_population"],
    n_children = args["n_children"],
    n_elites = args["n_elites"],
    communication_dimension = args["communication_dimension"],
    episode_length = args["episode_length"],
    n_nodes_per_output = args["n_nodes_per_output"],
    function_set = args["function_set"],
    mutation = args["mutation"],
    noise_std = args["noise_std"],
)

println("Running experiment with seed $(args["seed"])...")
println("experiment: $config")

evolve!(config)

println("Done!")