using Distributed
addprocs(4, exeflags="--project=.")
@everywhere using CoEvo

@everywhere function lingpredspawner(
    spid::Symbol; npop::Int = 50, dtype::Type = UInt32, 
    probs::Dict{Function, Float64} = Dict(
        addstate => 0.25,
        rmstate => 0.25,
        changelink => 0.25,
        changelabel => 0.25
))
    s = Spawner(
        spid = spid,
        npop = npop,
        icfg = FSMIndivConfig(spid = spid, dtype = dtype),
        phenocfg = FSMPhenoCfg(usemin = true, usesets = false),
        replacer = CommaReplacer(npop = npop),
        selector =  RouletteSelector(μ = npop),
        recombiner = CloneRecombiner(),
        mutators = [LingPredMutator(probs = probs)],
        archiver = FSMIndivArchiver(
            log_popids = false, savegeno = true, savemingeno = false
        ),
    )
    spid => s
end

@everywhere function lingpredorder(oid::Symbol, spvec::Vector{Symbol}, domain::Domain)
    oid => AllvsAllCommaOrder(oid, spvec, domain, NullObsConfig())
end

@everywhere function rungrow(trial::Int, npop::Int, ngen::Int, parallel::Bool)
    eco = :grow
    seed = rand(UInt64)

    addprob = 9 / 30
    otherprob = 7 / 30
    probs = Dict(
        addstate => addprob,
        rmstate => otherprob,
        changelabel => otherprob,
        changelink => otherprob
    )
    spawner1 = lingpredspawner(:grow1; npop = npop, probs = probs)
    spawner2 = lingpredspawner(:grow2; npop = npop, probs = probs)
    order = lingpredorder(:ControlMatch, [:grow1, :grow2], LingPredGame(Control()))

    coevcfg = CoevConfig(;
        eco = eco,
        trial = trial,
        seed = seed,
        jobcfg = parallel ? ParallelPhenoJobConfig() : SerialPhenoJobConfig(),
        orders = Dict(order),
        spawners = Dict(spawner1, spawner2),
    )

    allsp = coevcfg()
    println("starting $eco-$trial")
    for gen in 1:ngen
        allsp = coevcfg(gen, allsp)
        if mod(gen, 100) == 0
            println("$eco-$trial: $gen")
        end
    end
    close(coevcfg.jld2file)
end

@everywhere function runctrl(trial::Int, npop::Int, ngen::Int, parallel::Bool)
    eco = :ctrl
    seed = rand(UInt64)
    spawner1 = lingpredspawner(:ctrl1; npop = npop)
    spawner2 = lingpredspawner(:ctrl2; npop = npop)
    order = lingpredorder(:ControlMatch, [:ctrl1, :ctrl2], LingPredGame(Control()))

    coevcfg = CoevConfig(;
        eco = eco,
        trial = trial,
        seed = seed,
        jobcfg = parallel ? ParallelPhenoJobConfig() : SerialPhenoJobConfig(),
        orders = Dict(order),
        spawners = Dict(spawner1, spawner2),
    )

    allsp = coevcfg()
    println("starting $eco-$trial")
    for gen in 1:ngen
        allsp = coevcfg(gen, allsp)
        if mod(gen, 100) == 0
            println("$eco-$trial: $gen")
        end
    end
    close(coevcfg.jld2file)
end

@everywhere function runcoop(trial::Int, npop::Int, ngen::Int, parallel::Bool)
    eco = :coop
    seed = rand(UInt64)
    spawner1 = lingpredspawner(:host; npop = npop)
    spawner2 = lingpredspawner(:symbiote; npop = npop)
    order = lingpredorder(:CoopMatch, [:host, :symbiote], LingPredGame(MatchCoop()))

    coevcfg = CoevConfig(;
        eco = eco,
        trial = trial,
        seed = seed,
        jobcfg = parallel ? ParallelPhenoJobConfig() : SerialPhenoJobConfig(),
        orders = Dict(order),
        spawners = Dict(spawner1, spawner2),
    )

    allsp = coevcfg()
    println("starting $eco-$trial")
    for gen in 1:ngen
        allsp = coevcfg(gen, allsp)
        if mod(gen, 100) == 0
            println("$eco-$trial: $gen")
        end
    end
    close(coevcfg.jld2file)
end

@everywhere function runcomp(trial::Int, npop::Int, ngen::Int, parallel::Bool)
    eco = :comp
    seed = rand(UInt64)
    spawner1 = lingpredspawner(:host; npop = npop)
    spawner2 = lingpredspawner(:parasite; npop = npop)
    order = lingpredorder(:CompMatch, [:host, :parasite], LingPredGame(MatchComp()))

    coevcfg = CoevConfig(;
        eco = eco,
        trial = trial,
        seed = seed,
        jobcfg = parallel ? ParallelPhenoJobConfig() : SerialPhenoJobConfig(),
        orders = Dict(order),
        spawners = Dict(spawner1, spawner2),
    )

    allsp = coevcfg()
    println("starting $eco-$trial")
    for gen in 1:ngen
        allsp = coevcfg(gen, allsp)
        if mod(gen, 100) == 0
            println("$eco-$trial: $gen")
        end
    end
    close(coevcfg.jld2file)
end

@everywhere function runmix(
    trial::Int, npop::Int, ngen::Int, parallel::Bool, domain1::Domain, domain2::Domain
)
    v1 = typeof(domain1).parameters[1]
    v2 = typeof(domain2).parameters[1]
    eco = Symbol("Mix-$(v1)-$(v2)")
    seed = rand(UInt64)

    spawner1 = lingpredspawner(:host;     npop = npop)
    spawner2 = lingpredspawner(:symbiote; npop = npop)
    spawner3 = lingpredspawner(:parasite; npop = npop)

    order1 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], domain1)
    order2 = lingpredorder(:HostVsParasite, [:host, :parasite], domain2)

    coevcfg = CoevConfig(;
        eco = eco,
        trial = trial,
        seed = seed,
        jobcfg = parallel ? ParallelPhenoJobConfig() : SerialPhenoJobConfig(),
        orders = Dict(order1, order2),
        spawners = Dict(spawner1, spawner2, spawner3),
    )

    allsp = coevcfg()
    println("starting: $eco")
    for gen in 1:ngen
        allsp = coevcfg(gen, allsp)
        if mod(gen, 100) == 0
            println("Generation: $gen")
        end
    end
    close(coevcfg.jld2file)
end

function pdispatch(;
    fn::Function = runmix, trange::UnitRange = 1:20, npop::Int = 50, ngen::Int = 10_000,
    domains::Vector{<:Domain} = [LingPredGame(MismatchCoop()), LingPredGame(MatchComp())]
)
    futures = [@spawnat :any fn(trial, npop, ngen, false, domains...) for trial in trange] 
    [fetch(f) for f in futures]
end

function sdispatch(;
    fn::Function = runctrl, trange::UnitRange = 1:20, npop::Int = 50, ngen::Int = 10_000,
    domains::Vector{<:Domain} = [LingPredGame(MatchCoop()), LingPredGame(MatchComp())]
)
    [fn(trial, npop, ngen, false, domains...) for trial in trange] 
end