using Test
using Random
using ProfileView
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary
# include("util.jl")

function testspawner(rng::AbstractRNG, spid::Symbol; n_pop = 10, width = 10)
    sc = SpawnCounter()
    Spawner(
        spid = spid,
        n_pop = n_pop,
        icfg = VectorIndivConfig(
            spid = spid,
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = width
        ),
        replacer = TruncationReplacer(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(sc = sc),
        mutators = Mutator[]
    )
end

function roulettespawner(rng::AbstractRNG, spid::Symbol; n_pop = 50, width = 100)
    sc = SpawnCounter()
    Spawner(
        spid = spid,
        n_pop = n_pop,
        icfg = VectorIndivConfig(
            spid = spid,
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = width
        ),
        replacer = GenerationalReplacer(n_elite = 10),
        selector =  RouletteSelector(rng = rng, μ = n_pop),
        recombiner = CloneRecombiner(sc = sc),
        mutators = [BitflipMutator(rng = rng, sc = sc, mutrate = 0.05)]
    )
end

function testorder()
    AllvsAllOrder(
        oid = :NG,
        domain = NGGradient(),
        obscfg = NGObsConfig(),
        phenocfgs = Dict(
            :A => SumPhenoConfig(role = :A),
            :B => SumPhenoConfig(role = :B),
        ),
    )
end

function vecorder()
    AllvsAllOrder(
        oid = :NG,
        domain = NGFocusing(),
        obscfg = NGObsConfig(),
        phenocfgs = Dict(
            :A => SubvecPhenoConfig(role = :A, subvec_width = 10),
            :B => SubvecPhenoConfig(role = :B, subvec_width = 10),
        ),
    )
end

function dummyikey()
    IndivKey(:spdummy, 1)
end

function dummytkey()
    TestKey(:odummy, Set([dummyikey()]))
end

function dummyvets(indivs::Set{<:Individual})
    Set(Veteran(indiv.ikey, indiv, Dict(dummytkey() => 1)) for indiv in indivs)
end

function dummyvets(sp::Species)
    Species(sp.spid, dummyvets(sp.pop), dummyvets(sp.children))
end

function evolve(ngen::Int, npop::Int)
    seed = UInt64(42)
    rng = StableRNG(seed)

    coev_cfg = CoevConfig(;
        key = "Coev Test",
        trial = 1,
        seed = seed,
        rng = rng,
        jobcfg = SerialJobConfig(),
        orders = Set([testorder()]), 
        spawners = Set([
            testspawner(rng, :A, n_pop = npop, width = 100),
            testspawner(rng, :B, n_pop = npop, width = 100),
        ]),
        loggers = Set([SpeciesLogger()]))
    gen = UInt16(1)
    allsp = coev_cfg()
    while gen < ngen
        println(gen)
        allsp = coev_cfg(gen, allsp)
        gen += UInt16(1)
    end
    close(coev_cfg.jld2file)
end
