using Test
using Random
using StatsBase
using StableRNGs
include("../../src/Coevolutionary.jl")
using .Coevolutionary


function dummyA(key::String)
    start = "A0"
    zeros = Set(["A0"])
    ones = Set(["A1"])
    links = LinkDict(
                ("A0", 0)  => "A1",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A1",
                ("A1", 1)  => "A0",
                )
    fsm = FSM(key, false, start, ones, zeros, links)
    FSMIndividual(key, fsm, minimize(fsm), DiscoRecord())
end

function newDummyA()
    start = "A0"
    zeros = Set(["A0"])
    ones = Set(["A1"])
    links = LinkDict(
                ("A0", 0)  => "A1",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A1",
                ("A1", 1)  => "A0",
                )
    FSMIndiv(IndivKey(:dummy, UInt32(1)), start, ones, zeros, links)
end

function dummyB()
    start = "B0"
    zeros = Set(["B0"])
    ones = Set(["B1"])
    links = LinkDict(
                ("B0", 0)  => "B0",
                ("B0", 1)  => "B1",
                ("B1", 0)  => "B0",
                ("B1", 1)  => "B1",
                )
    fsm = FSM(key, false, start, ones, zeros, links)
    FSMIndividual(key, fsm, minimize(fsm), DiscoRecord())
end

function newDummyB()
    start = "B0"
    zeros = Set(["B0"])
    ones = Set(["B1"])
    links = LinkDict(
                ("B0", 0)  => "B0",
                ("B0", 1)  => "B1",
                ("B1", 0)  => "B0",
                ("B1", 1)  => "B1",
                )
    FSMIndiv(IndivKey(:dummy, UInt32(1)), start, ones, zeros, links)
end


function lingpredspawner(rng::AbstractRNG, spid::Symbol; npop = 50, spargs=Any[])
    sc = SpawnCounter()
    s = Spawner(
        spid = spid,
        npop = npop,
        icfg = FSMIndivConfig(spid = spid, sc = sc, rng = rng),
        phenocfg = FSMPhenoCfg(),
        #replacer = GenerationalReplacer(),
        replacer = CommaReplacer(),
        selector =  RouletteSelector(rng = rng, μ = npop),
        recombiner = CloneRecombiner(sc = sc),
        mutators = [LingPredMutator(rng = rng, sc = sc)],
        spargs = spargs
    )
    spid => s
end

function lingpredorder(oid::Symbol, spvec::Vector{Symbol}, domain::Domain)
    oid => AllvsAllCommaOrder(oid, spvec, domain, LingPredObsConfig())
end

@testset "Coev" begin
    # RNG #
    coev_key = "NG: Gradient"
    trial = 1
    seed = UInt64(42)
    rng = StableRNG(seed)

    spawner1 = lingpredspawner(rng, :host;     npop = 50, spargs = Any[newDummyA()])
    spawner2 = lingpredspawner(rng, :symbiote; npop = 50, spargs = Any[newDummyB()])
    spawner3 = lingpredspawner(rng, :parasite; npop = 50, spargs = Any[newDummyB()])

    order1 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MatchComp()))
    order2 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))

    coev_cfg = CoevConfig(;
        key = "Coev Test",
        trial = 1,
        seed = seed,
        rng = rng,
        jobcfg = SerialPhenoJobConfig(),
        orders = Dict(order1, order2),
        spawners = Dict(spawner1, spawner2, spawner3),
        loggers = Logger[]
    )

    gen = UInt16(1)
    allsp = coev_cfg()
    allvets, outcomes = interact(coev_cfg, allsp)

    @test mean(meanfitness(vet) for (_, vet) in allvets[:host].pop) ≈ 1/3
    @test mean(meanfitness(vet) for (_, vet) in allvets[:parasite].pop) ≈ 2/3
    @test mean(meanfitness(vet) for (_, vet) in allvets[:symbiote].pop) ≈ 1/3
    close(coev_cfg.jld2file)
end


@testset "Coev2" begin
    coev_key = "Coev2"
    seed = UInt64(42)
    rng = StableRNG(seed)

    spawner1 = lingpredspawner(rng, :host;     npop = 50)
    spawner2 = lingpredspawner(rng, :symbiote; npop = 50)
    spawner3 = lingpredspawner(rng, :parasite; npop = 50)

    order1 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MatchComp()))
    order2 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))

    coev_cfg = CoevConfig(;
        key = coev_key,
        trial = 1,
        seed = seed,
        rng = rng,
        jobcfg = SerialPhenoJobConfig(),
        orders = Dict(order1, order2),
        spawners = Dict(spawner1, spawner2, spawner3),
        loggers = Logger[]
    )

    allsp = coev_cfg()
    for gen in 1:100
        allsp = coev_cfg(UInt16(gen), allsp)
    end
end