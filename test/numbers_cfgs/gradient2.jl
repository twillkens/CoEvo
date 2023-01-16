using Test
using Random
using StableRNGs
include("../../src/Coevolutionary.jl")
using .Coevolutionary
using ProgressBars
using Plots
using JLD2
using StatsBase

function run(;
        coev_key::String = "control",
        n_samples::Int = 15,
        domain::Domain = NGControl(),
        subvector_width = subvector_width,
        default_valA::Bool = false,
        default_valB::Bool = false,
        trial::Int = 1,
        rng::AbstractRNG = StableRNG(123),
        width::Int = 100,
        n_genos::Int = 25)

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
    pops = Set([popA, popB])

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
    orderA = SamplerOrder(
        domain = domain,
        outcome = TestPairOutcome,
        subjects_key = "B",
        subjects_cfg = VectorPhenoConfig(subvector_width = subvector_width),
        tests_key = "A",
        tests_cfg = VectorPhenoConfig(subvector_width = subvector_width),
        n_samples = n_samples,
        rng=rng,)
    orders = Set([orderA, orderB])

    ## Spawners ##
    mutrate = 0.05
    spawnerA = Spawner(
        key = "A", 
        selector = RouletteSelector(
            rng = rng,
            n_elite = 0,
            n_singles = n_genos,
            n_couples = 0),
        reproducer = BitstringReproducer(
            rng = rng,
            mutrate = mutrate))
    spawnerB = Spawner(
        key = "B", 
        selector = RouletteSelector(
            rng = rng,
            n_elite = 0,
            n_singles = n_genos,
            n_couples = 0),
        reproducer = BitstringReproducer(
            rng = rng,
            mutrate = mutrate))
    spawners = Set([spawnerA, spawnerB])

    ## Loggers ##
    loggers = Set([BasicGeneLogger("A"), FitnessLogger("A"),
                   BasicGeneLogger("B"), FitnessLogger("B")])
    coev_cfg = CoevConfig(;
        key=coev_key,
        trial=trial,
        job_cfg=job_cfg,
        orders=orders, 
        spawners=spawners,
        loggers=loggers,
        logpath=string("data/", coev_key, ".jld2"))
    for gen in ProgressBar(1:600)
        pops = coev_cfg(gen, pops)
    end
    close(coev_cfg.jld2file)
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

function plot_popsums(logpath::String)
    log = jldopen(string("data/", logpath, ".jld2"), "r")
    sumsA = get_popsums(log, "A")
    sumsB = get_popsums(log, "B")
    plot([sumsA, sumsB])
    savefig(string("data/", logpath, ".png"))
end

function make_trialdict()
    control = (coev_key::String) -> run(;coev_key = coev_key, domain = NGControl())
    gradient1 = (coev_key::String) -> run(;coev_key = coev_key, domain = NGGradient())
    gradient2 = (coev_key::String) -> run(;coev_key = coev_key, n_samples = 1,
                                           domain = NGGradient())
    focusing = (coev_key::String) -> run(;coev_key = coev_key, domain = NGFocusing())
    relativism = (coev_key::String) -> run(;coev_key = coev_key, domain = NGRelativism())
    Dict(
        "control" => control,
        "gradient1" => gradient1,
        "gradient2" => gradient2,
        "focusing" => focusing,
        "relativism" => relativism,
    )
end

function runtrials(trials::Vector{String})
    trialdict = make_trialdict()
    [trialdict[trial]() for trial in trials]
    [plot_popsums(trial) for trial in trials]
end
