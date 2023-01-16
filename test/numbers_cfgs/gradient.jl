using Test
using Random
using StableRNGs
include("../../src/Coevolutionary.jl")
using .Coevolutionary
using ProgressBars
using Plots
using JLD2

function run()
    # RNG #
    coev_key = "NG: Control"
    trial = 1
    rng = StableRNG(123)

    ## Populations ##
    width = 100
    n_genos = 25
    popA = GenoPopConfig(
        key="A", n_genos=n_genos,
        geno_cfg=DefaultBitstringConfig(width=width, default_val=false))()
    popB = GenoPopConfig(
        key="B", n_genos=n_genos,
        geno_cfg=DefaultBitstringConfig(width=width, default_val=false))()
    pops = Set([popA, popB])

    ## Job ##
    job_cfg = SerialJobConfig()

    ## Orders ##
    n_samples = 15

    domain = NGGradient()
    pheno_cfg = IntPhenoConfig()
    orderA = SamplerOrder(
        domain=domain, outcome=TestPairOutcome,
        subjects_key="A", subjects_cfg=pheno_cfg,
        tests_key="B", tests_cfg=pheno_cfg,
        n_samples=n_samples, rng=rng)
    orderB = SamplerOrder(
        domain=domain, outcome=TestPairOutcome,
        subjects_key="B", subjects_cfg=pheno_cfg,
        tests_key="A", tests_cfg=pheno_cfg,
        n_samples=n_samples, rng=rng)
    orders = Set([orderA, orderB])

    ## Spawners ##
    mutrate = 0.05
    selectorA = RouletteSelector(rng=rng, n_elite=0, n_singles=n_genos, n_couples=0)
    reproducerA = BitstringReproducer(rng=rng, mutrate=mutrate)
    spawnerA = Spawner("A", selectorA, reproducerA)
    selectorB = RouletteSelector(rng=rng, n_elite=0, n_singles=n_genos, n_couples=0)
    reproducerB = BitstringReproducer(rng=rng, mutrate=mutrate)
    spawnerB = Spawner("B", selectorB, reproducerB)
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
        logpath="gradient.jld2")
    for gen in ProgressBar(1:600)
        pops = coev_cfg(gen, pops)
    end
end
run()
