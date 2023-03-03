
# using Test
# using Random
# using StableRNGs
# using CoEvo
# using StatsBase

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


function lingpredspawner(spid::Symbol; npop::Int = 50, dtype::Type = Int, spargs = Any[])
    s = Spawner(
        spid = spid,
        npop = npop,
        icfg = FSMIndivConfig(spid = spid, dtype = dtype),
        phenocfg = FSMPhenoCfg(minimize = true),
        replacer = GenerationalReplacer(npop = npop, n_elite = 5),
        selector =  RouletteSelector(μ = npop),
        recombiner = CloneRecombiner(),
        mutators = [LingPredMutator()],
        archiver = FSMIndivArchiver(log_popids = true, minimize = true),
        spargs = spargs
    )
    spid => s
end

function lingpredorder(oid::Symbol, spvec::Vector{Symbol}, domain::Domain)
    oid => AllvsAllPlusOrder(oid, spvec, domain, LingPredObsConfig())
end

@testset "Coev" begin
    # RNG #
    trial = 1
    seed = UInt64(42)

    spawner1 = lingpredspawner(:host;     npop = 50, spargs = Any[newDummyA()])
    spawner2 = lingpredspawner(:symbiote; npop = 50, spargs = Any[newDummyB()])
    spawner3 = lingpredspawner(:parasite; npop = 50, spargs = Any[newDummyB()])

    order1 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MatchComp()))
    order2 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))

    coev_cfg = CoevConfig(;
        eco = :FSMTest,
        trial = 1,
        seed = seed,
        spawners = Dict(spawner1, spawner2, spawner3),
        orders = Dict(order1, order2),
        jobcfg = SerialPhenoJobConfig(),
        loggers = Logger[]
    )

    gen = 1
    allsp = coev_cfg()
    allvets, outcomes = interact(coev_cfg, allsp)

    @test mean(meanfitness(vet) for (_, vet) in allvets[:host].children) ≈ 1/3
    @test mean(meanfitness(vet) for (_, vet) in allvets[:parasite].children) ≈ 2/3
    @test mean(meanfitness(vet) for (_, vet) in allvets[:symbiote].children) ≈ 1/3
    close(coev_cfg.jld2file)
    rm("archives/FSMTest/1.jld2")
end

@testset "Coev2/Unfreeze" begin
    # RNG #
    trial = 1
    seed = UInt64(42)

    spawner1 = lingpredspawner(:host;     npop = 50)
    spawner2 = lingpredspawner(:symbiote; npop = 50)
    spawner3 = lingpredspawner(:parasite; npop = 50)

    order1 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MatchComp()))
    order2 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))

    c1 = CoevConfig(;
        eco = :FSMTest,
        trial = 2,
        seed = seed,
        spawners = Dict(spawner1, spawner2, spawner3),
        orders = Dict(order1, order2),
        jobcfg = SerialPhenoJobConfig(),
        loggers = Logger[]
    )

    allsp = c1()
    c1_evostate = nothing

    for gen in 1:9
        lastsp = allsp
        if gen == 9
            c1_evostate = deepcopy(c1.evostate)
        end
        allsp = c1(gen, allsp)
    end
    close(c1.jld2file)
    gen, c2, allsp = unfreeze("archives/FSMTest/2.jld2")
    @test gen == 10
    @test c1.eco == c2.eco
    @test c1.trial == c2.trial
    @test c1_evostate.rng == c2.evostate.rng
    @test c1_evostate.counters[:host].iid == c2.evostate.counters[:host].iid
    @test c1_evostate.counters[:host].gid == c2.evostate.counters[:host].gid
    @test c1.jobcfg == c2.jobcfg
    s1, s2 = c1.spawners[:host], c2.spawners[:host]
    @test s1.icfg == s2.icfg
    @test s1.phenocfg == s2.phenocfg
    @test s1.replacer == s2.replacer
    @test s1.selector == s2.selector
    @test s1.recombiner == s2.recombiner
    @test s1.mutators[1].nchanges == s2.mutators[1].nchanges
    @test s1.mutators[1].probs == s2.mutators[1].probs
    @test s1.archiver == s2.archiver
    o1, o2 = c1.orders[:HostVsParasite], c2.orders[:HostVsParasite]
    @test all(getproperty(o1, fname) == getproperty(o2, fname)
        for fname in fieldnames(AllvsAllPlusOrder))
    @test c1.loggers == c2.loggers
    rm("archives/FSMTest/2.jld2")
end


# @testset "Coev2" begin
#     coev_key = "Coev2"
#     seed = UInt64(42)
#     rng = StableRNG(seed)
# 
#     spawner1 = lingpredspawner(rng, :host;     npop = 50)
#     spawner2 = lingpredspawner(rng, :symbiote; npop = 50)
#     spawner3 = lingpredspawner(rng, :parasite; npop = 50)
# 
#     order1 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MatchComp()))
#     order2 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))
# 
#     coev_cfg = CoevConfig(;
#         key = coev_key,
#         trial = 1,
#         seed = seed,
#         rng = rng,
#         jobcfg = SerialPhenoJobConfig(),
#         orders = Dict(order1, order2),
#         spawners = Dict(spawner1, spawner2, spawner3),
#         loggers = Logger[]
#     )
# 
#     allsp = coev_cfg()
#     for gen in 1:100
#         allsp = coev_cfg(UInt16(gen), allsp)
#     end
# end