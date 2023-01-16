using Test
using Random
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary
using ProgressBars
using Plots
using JLD2
using StatsBase

function make_coevcfg(;
        coev_key::String = "control",
        n_samples::Int = 15,
        domain::Domain = NGControl(),
        subvector_width = 10,
        default_valA::Bool = false,
        default_valB::Bool = false,
        trial::Int = 1,
        rng::AbstractRNG = StableRNG(Int(rand(UInt64))),
        width::Int = 100,
        n_genos::Int = 25,
        n_elite::Int = 0,
        n_singles::Int = 25,
        n_couples::Int = 0,
        )

    ## Populations ##
    popA = GenoPopConfig(
        key = "A",
        n_genos = n_genos,
        geno_cfg = DefaultBitstringConfig(
            width = width,
            default_val = default_valA))()
    popB = GenoPopConfig(
        key = "B",
        n_genos = n_genos,
        geno_cfg = DefaultBitstringConfig(
            width = width,
            default_val = default_valB))()
    pops = Set([
        popA,
        popB,
        ])

    ## Job ##
    job_cfg = SerialJobConfig()

    ## Orders ##
    orderA = SamplerOrder(
        domain = domain,
        outcome = TestPairOutcome,
        subjects_key = "A",
        subjects_cfg = VectorPhenoConfig(subvector_width = subvector_width),
        tests_key = "B",
        tests_cfg = VectorPhenoConfig(subvector_width = subvector_width),
        n_samples = n_samples,
        rng=rng,)
    orderB = SamplerOrder(
        domain = domain,
        outcome = TestPairOutcome,
        subjects_key = "B",
        subjects_cfg = VectorPhenoConfig(subvector_width = subvector_width),
        tests_key = "A",
        tests_cfg = VectorPhenoConfig(subvector_width = subvector_width),
        n_samples = n_samples,
        rng=rng,)
    orders = Set([
        orderA,
        orderB,
        ])

    ## Spawners ##
    mutrate = 0.05
    spawnerA = Spawner(
        key = "A", 
        selector = RouletteOldSelector(
            rng = rng,
            n_elite = n_elite,
            n_singles = n_singles,
            n_couples = n_couples,
            ),
        reproducer = BitstringReproducer(
            rng = rng,
            mutrate = mutrate,
            ))
    spawnerB = Spawner(
        key = "B", 
        selector = RouletteOldSelector(
            rng = rng,
            n_elite = n_elite,
            n_singles = n_singles,
            n_couples = n_couples,
            ),
        reproducer = BitstringReproducer(
            rng = rng,
            mutrate = mutrate))
    spawners = Set([
        spawnerA, 
        spawnerB,
        ])

    ## Loggers ##
    loggers = Set([
        BasicGeneLogger("A"),
        FitnessLogger("A"),
        BasicGeneLogger("B"),
        FitnessLogger("B"),
        ])

    ## Construct and return cfg
    coev_cfg = CoevConfig(;
        key = coev_key,
        trial = trial,
        job_cfg = job_cfg,
        orders = orders, 
        spawners = spawners,
        loggers = loggers,
        logpath = "data/$(coev_key)-$(trial).jld2",
        )
    pops, coev_cfg
end

function run_trial(; kwargs...)
    pops, coev_cfg = make_coevcfg(; kwargs...)
    for gen in ProgressBar(1:100)
        pops = coev_cfg(gen, pops)
    end
    close(coev_cfg.jld2file)
end


function make_trialdict(rng::AbstractRNG, trial::Int)
    Dict(
        "control" => 
        (coev_key::String) -> run_trial(;
        coev_key = coev_key,
        default_valA = true,
        domain = NGControl(),
        rng = rng,
        trial = trial,
        ),

        "gradient1" => 
        (coev_key::String) -> run_trial(;
        coev_key = coev_key,
        domain = NGGradient(),
        rng = rng,
        trial = trial,
        ),

        "gradient1-elites" => 
        (coev_key::String) -> run_trial(;
        coev_key = coev_key,
        n_samples = 15,
        domain = NGGradient(),
        n_elite = 5,
        n_singles = 20,
        rng = rng,
        trial = trial,
        ),

        "gradient2" => 
        (coev_key::String) -> run_trial(;
        coev_key = coev_key,
        n_samples = 1,
        domain = NGGradient(),
        rng = rng,
        trial = trial,
        ),

        "gradient2-elites" => 
        (coev_key::String) -> run_trial(;
        coev_key = coev_key,
        n_samples = 1,
        domain = NGGradient(),
        n_elite = 5,
        n_singles = 20,
        rng = rng,
        trial = trial,
        ),

        "gradient3" => 
        (coev_key::String) -> run_trial(;
        coev_key = coev_key,
        n_samples = 100,
        domain = NGGradient(),
        rng = rng,
        trial = trial,
        ),

        "focusing" =>
        (coev_key::String) -> run_trial(;
        coev_key = coev_key,
        domain = NGFocusing(),
        rng = rng,
        trial = trial,
        ),

        "relativism" => 
        (coev_key::String) -> run_trial(;
        coev_key = coev_key,
        domain = NGRelativism(),
        rng = rng,
        trial = trial,
        )
    )
end

function get_popsums(log, popkey)
    data = Float64[]
    for i in 1:600
        group = log[string(i)]["pops"][popkey]
        pop_sums = [sum(group[key]["genes"]) for key in keys(group)]
        push!(data, mean(pop_sums))
    end
    data
end

function get_fitness(log, popkey)
    data = Float64[]
    for i in 1:600
        group = log[string(i)]["pops"][popkey]
        fitness = [group[key]["fitness_stats"].mean for key in keys(group)]
        push!(data, mean(fitness))
    end
    data
end

function plot_pop(eco::String, trial::Int)
    logpath = "data/$(eco)-$(trial).jld2"
    log = jldopen(logpath, "r")
    sumsA = get_popsums(log, "A")
    sumsB = get_popsums(log, "B")
    fitA = get_fitness(log, "A")
    fitB = get_fitness(log, "B")
    close(log)
    p1 = plot([sumsA, sumsB])
    p2 = plot(fitA)
    p3 = plot(fitB)
    plot(p1, p2, p3,
        layout = grid(3, 1, heights=[0.6, 0.2, 0.2]))
    figpath = "data/$(eco)-$(trial).png"
    savefig(figpath)
end

function runtrials(rng::AbstractRNG, trial::Int, ecos::Vector{String})
    trialdict = make_trialdict(rng, trial)
    [trialdict[eco](eco) for eco in ecos]
    [plot_pop(eco, trial) for eco in ecos]
end

runtrials(
    StableRNG(Int(rand(UInt32))),
    3,
[
    # "control",
    # "gradient1",
    # "gradient1-elites",
    "gradient2",
    # "gradient2-elites",
    # "gradient3",
    # "focusing",
    # "relativism",
    ])