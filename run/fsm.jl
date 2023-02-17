using Distributed
@everywhere using Random
@everywhere using StableRNGs
@everywhere include("../src/Coevolutionary.jl")
@everywhere using .Coevolutionary

@everywhere function lingpredspawner(rng::AbstractRNG, spid::Symbol; npop = 50, spargs=Any[])
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

@everywhere function lingpredorder(oid::Symbol, spvec::Vector{Symbol}, domain::Domain)
    oid => AllvsAllCommaOrder(oid, spvec, domain, LingPredObsConfig())
end


@everywhere function runcoop(i::Int)
    coev_key = "Coop-$(i)"
    seed = rand(UInt64)
    rng = StableRNG(seed)

    spawner1 = lingpredspawner(rng, :host;     npop = 50)
    spawner2 = lingpredspawner(rng, :symbiote; npop = 50)
    # spawner3 = lingpredspawner(rng, :parasite; npop = 50)

    order1 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))
    #order1 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MatchComp()))

    coev_cfg = CoevConfig(;
        key = coev_key,
        trial = i,
        seed = seed,
        rng = rng,
        jobcfg = SerialPhenoJobConfig(),
        orders = Dict(order1),
        spawners = Dict(spawner1, spawner2), #, spawner3),
        loggers = [SpeciesLogger()],
        logpath = "/media/tcw/Seagate/NewLing/coop-$(i).jld2"
    )

    allsp = coev_cfg()
    println("go")
    for gen in 1:10_000
        allsp = coev_cfg(UInt16(gen), allsp)
        if mod(gen, 1000) == 0
            println("Generation: $gen")
        end
    end
    close(coev_cfg.jld2file)
end


@everywhere function runcomp(i::Int)
    coev_key = "Comp-$(i)"
    seed = rand(UInt64)
    rng = StableRNG(seed)

    spawner1 = lingpredspawner(rng, :host;     npop = 50)
    # spawner2 = lingpredspawner(rng, :symbiote; npop = 50)
    spawner3 = lingpredspawner(rng, :parasite; npop = 50)

    #order1 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))
    order2 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MatchComp()))

    coev_cfg = CoevConfig(;
        key = coev_key,
        trial = i,
        seed = seed,
        rng = rng,
        jobcfg = SerialPhenoJobConfig(),
        orders = Dict(order2),
        spawners = Dict(spawner1, spawner3), #, spawner3),
        loggers = [SpeciesLogger()],
        logpath = "/media/tcw/Seagate/NewLing/comp-$(i).jld2"
    )

    allsp = coev_cfg()
    println("go")
    for gen in 1:10_000
        allsp = coev_cfg(UInt16(gen), allsp)
        if mod(gen, 1000) == 0
            println("Generation: $gen")
        end
    end
    close(coev_cfg.jld2file)
end


function dispatch()
    workerjobs = [[worker, 0] for worker in 2:6 for i in 1:10]

    for i in 1:50
        workerjobs[i][2] = i
    end

    futures = [remotecall(runcoop, worker, job) for (worker, job) in workerjobs]
    [fetch(f) for f in futures]
    futures = [remotecall(runcomp, worker, job) for (worker, job) in workerjobs]
    [fetch(f) for f in futures]
end


# write a loop to assign five jobs each to ten workers using remotecall so that each job number is unique from one to fifty 
# and each worker number is unique from one to ten.

#    addprocs(10)







#    futures = [remotecall(run, worker, ) for worker in 1:10 for ]
#    outcomes = [fetch(f) for f in futures]