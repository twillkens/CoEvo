using Test
using Random
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary

@testset Spawner begin
@testset "Coev" begin
    # RNG #
    coev_key = "NG: Control"
    trial = 1
    rng = StableRNG(123)

    ## Populations ##
    width = 100
    n_genos = 25
    popA = GenoPopConfig(
        key = "A",
        n_genos = n_genos,
        geno_cfg = DefaultBitstringConfig(
            width = width,
            default_val=true))()
    popB = GenoPopConfig(
        key = "B",
        n_genos = n_genos,
        geno_cfg = DefaultBitstringConfig(
            width = width,
            default_val = false))()
    pops = Set([popA, popB])

    ## Job ##
    job_cfg = SerialJobConfig()

    orderA = AllvsAllMixOrder(
        domain = NGGradient(),
        outcome = ScoreOutcome,
        poproles = Dict(
            "A" => PopRole(
                role = :subject,
                phenocfg = IntPhenoConfig()),
            "B" => PopRole(
                role = :test,
                phenocfg = IntPhenoConfig()),
        ),)
    orders = Set([orderA,])

    ## Spawners ##
    mutrate = 0.05
    selector = RouletteSelector(
        rng = rng,
        n_elite=0, n_singles=n_genos, n_couples=0)
    variator = BitstringMutator(
        rng = rng,
        mutrate = mutrate)
    spawnerA = Spawner("A", selectorA, reproducerA, GenoPop)
    selectorB = RouletteSelector(rng=rng, n_elite=0, n_singles=n_genos, n_couples=0)
    reproducerB = BitstringReproducer(rng=rng, mutrate=mutrate)
    spawnerB = Spawner("B", selectorB, reproducerB, GenoPop)
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
        loggers=loggers,)
    gen = 1
    while gen < 200
        gen += 1
        pops = coev_cfg(gen, pops)
    end
end
end