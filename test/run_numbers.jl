using Test
using Random
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary
include("util.jl")


function evolve(ngen::Int, npop::Int)
    # RNG #
    coev_key = "NG: Gradient"
    seed = UInt64(42)
    rng = StableRNG(seed)
    phenocfg = SumPhenoConfig()

    coev_cfg = CoevConfig(;
        key = coev_key,
        trial = 1,
        seed = seed,
        rng = rng,
        jobcfg = SerialPhenoJobConfig(),
        orders = Dict(:NG => testorder()),
        spawners = Dict(
            :A => testspawner(rng, :A; npop = npop, width = 100, phenocfg = phenocfg),
            :B => testspawner(rng, :B; npop = npop, width = 100, phenocfg = phenocfg),
        ),
        loggers = [SpeciesLogger()])
    gen = UInt16(1)
    allsp = coev_cfg()
    while gen < ngen
        println(gen)
        allsp = coev_cfg(gen, allsp)
        gen += UInt16(1)
    end
    close(coev_cfg.jld2file)
end

Spawner{VectorIndivConfig, SumPhenoConfig, TruncationReplacer, IdentitySelector, CloneRecombiner, Mutator}(:A, 100, VectorIndivConfig(:A, Bool, 100, VectorIndiv), SumPhenoConfig(), TruncationReplacer(100), IdentitySelector(), CloneRecombiner(), Mutator[], Any[]) == 
Spawner{VectorIndivConfig, SumPhenoConfig, TruncationReplacer, IdentitySelector, CloneRecombiner, Mutator}(:A, 100, VectorIndivConfig(:A, Bool, 100, VectorIndiv), SumPhenoConfig(), TruncationReplacer(100), IdentitySelector(), CloneRecombiner(), Mutator[], Any[])