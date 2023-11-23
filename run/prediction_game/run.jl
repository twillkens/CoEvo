using Distributed
#using ClusterManagers
using ArgParse

function parse_cmdline_args()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--trial"
            arg_type = Int
            default = 1
            required = true
            help = "Trial ID"
        "--seed"
            arg_type = Int
            required = false
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
        "--reproduction"
            arg_type = String
            default = "roulette"
            help = "Reproduction method"
        "--topology"
            arg_type = String
            default = "two_control"
            help = "Ecosystem topology"
        "--report_type"
            arg_type = String
            default = "verbose_test"
            help = "Report type"
        "--communication_dimension"
            arg_type = Int
            default = 0
            help = "Communication dimension"
        "--episode_length"
            arg_type = Int
            default = 16
            help = "Episode length"
    end

    return parse_args(s)
end

args = parse_cmdline_args()

# Add workers for this trial
if args["n_workers"] > 1
    addprocs(args["n_workers"])
end

@everywhere begin
    using CoEvo
    using CoEvo: PredictionGameConfiguration
    using StableRNGs: StableRNG
end

configuration = PredictionGameConfiguration(;
    trial = args["trial"],
    n_population = args["n_population"],
    random_number_generator = args["seed"],
    report_type = args["report_type"],
    reproduction_method = args["reproduction"],
    cohorts = ["population", "children"],
    communication_dimension = args["communication_dimension"],
    n_workers = args["n_workers"],
    episode_length = args["episode_length"],
    ecosystem_topology = args["topology"],
)

run!(configuration; n_generations = args["n_generations"])