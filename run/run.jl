using Distributed
using ClusterManagers
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
            default = 1000
            help = "Number of generations"
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

configuration = PredictionGameConfiguration(
    trial = args["trial"],
    n_population = 50,
    random_number_generator = StableRNG(args["seed"]),
    report_type = :deploy,
    reproduction_method = :disco,
    cohorts = [:population, :children],
    communication_dimension = 0,
    n_workers = args["n_workers"],
    episode_length = 16,
    ecosystem_topology = :two_species_competitive
)

run!(configuration; n_generations = args["n_generations"])