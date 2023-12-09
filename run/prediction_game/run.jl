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
            default = "two_control"
            help = "Ecosystem topology"
        "--substrate"
            arg_type = String
            default = "function_graphs"
            help = "Substrate type"
        "--reproducer"
            arg_type = String
            default = "roulette"
            help = "Reproduction method"
        "--report"
            arg_type = String
            default = "verbose_test"
            help = "Report type"
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
            default = 100
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
        "--modes_interval"
            arg_type = Int
            default = 50
            help = "Modes interval"
        "--function_set"
            arg_type = String
            default = "all"
            help = "Function set"
        "--mutation"
            arg_type = String
            default = "equal_volatile"
            help = "Mutation type"
        "--noise_std"
            arg_type = String
            default = "moderate"
            help = "Noise standard deviation"
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
    using CoEvo: make_prediction_game_experiment    
    using StableRNGs: StableRNG
end

experiment = make_prediction_game_experiment(;
    game = args["game"],
    topology = args["topology"],
    substrate = args["substrate"],
    reproducer = args["reproducer"],
    trial = args["trial"],
    n_population = args["n_population"],
    n_children = args["n_children"],
    seed = args["seed"],
    report = args["report"],
    cohorts = ["population", "children"],
    communication_dimension = args["communication_dimension"],
    n_workers = args["n_workers"],
    episode_length = args["episode_length"],
    n_nodes_per_output = args["n_nodes_per_output"],
    modes_interval = args["modes_interval"],
    function_set = args["function_set"],
    mutation = args["mutation"],
    noise_std = args["noise_std"],
)

println("Running experiment...")

run!(experiment; n_generations = args["n_generations"])

println("Done!")