using Distributed
#addprocs(4, exeflags="--project=.")
@everywhere using Pkg
@everywhere Pkg.activate(".")
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

@everywhere function rungrow(trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int)
    eco = :grow
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
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
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(order),
            spawners = Dict(spawner1, spawner2),
            arxiv_interval = arxiv_interval
        )
        allsp = coevcfg()
    end
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function runctrl(
    trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int
)
    eco = :ctrl
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
        seed = rand(UInt64)
        spawner1 = lingpredspawner(:ctrl1; npop = npop)
        spawner2 = lingpredspawner(:ctrl2; npop = npop)
        order = lingpredorder(:ControlMatch, [:ctrl1, :ctrl2], LingPredGame(Control()))
        coevcfg = CoevConfig(;
            eco = eco,
            trial = trial,
            seed = seed,
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(order),
            spawners = Dict(spawner1, spawner2),
            arxiv_interval = arxiv_interval
        )
        allsp = coevcfg()
    end
    println("starting $eco-$trial")
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function runcoop(trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int)
    eco = :coop
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
        seed = rand(UInt64)
        spawner1 = lingpredspawner(:host; npop = npop)
        spawner2 = lingpredspawner(:symbiote; npop = npop)
        order = lingpredorder(:CoopMatch, [:host, :symbiote], LingPredGame(MatchCoop()))
        coevcfg = CoevConfig(;
            eco = eco,
            trial = trial,
            seed = seed,
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(order),
            spawners = Dict(spawner1, spawner2),
            arxiv_interval = arxiv_interval
        )
        allsp = coevcfg()
    end
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function runcomp(trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int)
    eco = :comp
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
        seed = rand(UInt64)
        spawner1 = lingpredspawner(:host; npop = npop)
        spawner2 = lingpredspawner(:parasite; npop = npop)
        order = lingpredorder(:CompMatch, [:host, :parasite], LingPredGame(MatchComp()))
        coevcfg = CoevConfig(;
            eco = eco,
            trial = trial,
            seed = seed,
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(order),
            spawners = Dict(spawner1, spawner2),
            arxiv_interval = arxiv_interval
        )
    end
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function run_matchcycle(
    trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int, 
)
    eco = Symbol("matchcycle")
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
        seed = rand(UInt64)
        spawner1 = lingpredspawner(:x; npop = npop)
        spawner2 = lingpredspawner(:y; npop = npop)
        spawner3 = lingpredspawner(:z; npop = npop)
        order1 = lingpredorder(:xy, [:x, :y], LingPredGame(MatchComp()))
        order2 = lingpredorder(:yz, [:y, :z], LingPredGame(MatchComp()))
        order3 = lingpredorder(:zx, [:z, :x], LingPredGame(MatchComp()))
        coevcfg = CoevConfig(;
            eco = eco,
            trial = trial,
            seed = seed,
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(order1, order2, order3),
            spawners = Dict(spawner1, spawner2, spawner3),
            arxiv_interval = arxiv_interval,
        )
        allsp = coevcfg()
    end
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function run_mismatchcycle(
    trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int, 
)
    eco = Symbol("mismatchcycle")
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
        seed = rand(UInt64)
        spawner1 = lingpredspawner(:x; npop = npop)
        spawner2 = lingpredspawner(:y; npop = npop)
        spawner3 = lingpredspawner(:z; npop = npop)
        order1 = lingpredorder(:xy, [:x, :y], LingPredGame(MatchComp()))
        order2 = lingpredorder(:yz, [:y, :z], LingPredGame(MismatchComp()))
        order3 = lingpredorder(:zx, [:z, :x], LingPredGame(MatchComp()))
        coevcfg = CoevConfig(;
            eco = eco,
            trial = trial,
            seed = seed,
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(order1, order2, order3),
            spawners = Dict(spawner1, spawner2, spawner3),
            arxiv_interval = arxiv_interval,
        )
        allsp = coevcfg()
    end
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function run_matchmix(
    trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int
)
    eco = Symbol("matchmix")
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
        seed = rand(UInt64)
        spawner1 = lingpredspawner(:host;     npop = npop)
        spawner2 = lingpredspawner(:symbiote; npop = npop)
        spawner3 = lingpredspawner(:parasite; npop = npop)
        order1 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))
        order2 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MatchComp()))
        coevcfg = CoevConfig(;
            eco = eco,
            trial = trial,
            seed = seed,
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(order1, order2),
            spawners = Dict(spawner1, spawner2, spawner3),
            arxiv_interval = arxiv_interval,
        )
        allsp = coevcfg()
    end
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function run_mismatchmix(
    trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int
)
    eco = Symbol("mismatchmix")
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
        seed = rand(UInt64)
        spawner1 = lingpredspawner(:host;     npop = npop)
        spawner2 = lingpredspawner(:symbiote; npop = npop)
        spawner3 = lingpredspawner(:parasite; npop = npop)
        order1 = lingpredorder(:HostVsSymbiote, [:host, :symbiote], LingPredGame(MatchCoop()))
        order2 = lingpredorder(:HostVsParasite, [:host, :parasite], LingPredGame(MismatchComp()))
        coevcfg = CoevConfig(;
            eco = eco,
            trial = trial,
            seed = seed,
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(order1, order2),
            spawners = Dict(spawner1, spawner2, spawner3),
            arxiv_interval = arxiv_interval,
        )
        allsp = coevcfg()
    end
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function run_4MatchMix(
    trial::Int, npop::Int, ngen::Int, njobs::Int, arxiv_interval::Int, 
)
    eco = Symbol("4MatchMix")
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
    jld2path = joinpath(ecodir, "$(trial).jld2")
    if isfile(jld2path)
        start, coevcfg, allsp = unfreeze(jld2path)
    else
        start = 1
        seed = rand(UInt64)
        coevcfg = CoevConfig(;
            eco = eco,
            trial = trial,
            seed = seed,
            jobcfg = njobs == 0 ? SerialPhenoJobConfig() : ParallelPhenoJobConfig(njobs = njobs),
            orders = Dict(
                lingpredorder(:AB, [:A, :B], LingPredGame(MatchComp())),
                lingpredorder(:AC, [:A, :C], LingPredGame(MatchCoop())),
                lingpredorder(:BD, [:B, :D], LingPredGame(MatchCoop())),
            ),
            spawners = Dict(
                lingpredspawner(:A; npop = npop), 
                lingpredspawner(:B; npop = npop), 
                lingpredspawner(:C; npop = npop), 
                lingpredspawner(:D; npop = npop),
            ),
            arxiv_interval = arxiv_interval,
        )
        allsp = coevcfg()
    end
    evolve!(start, ngen, coevcfg, allsp, eco, trial)
end

@everywhere function evolve!(
    start::Int, ngen::Int, coevcfg::CoevConfig, allsp::Dict{Symbol, <:Species},
    eco::Symbol, trial::Int
)
    println("starting: $eco-$trial")
    for gen in start:ngen
        allsp = coevcfg(gen, allsp)
    end
end

function pdispatch(;
    fn::Function = runctrl, trange::UnitRange = 1:20, npop::Int = 50, ngen::Int = 50_000,
    njobs::Int = 0, arxiv_interval::Int = 1000,
)
    futures = [
        @spawnat :any fn(trial, npop, ngen, njobs, arxiv_interval) 
        for trial in trange
    ] 
    [fetch(f) for f in futures]
end

function sdispatch(;
    fn::Function = runctrl, trange::UnitRange = 1:20, npop::Int = 50, ngen::Int = 50_000,
    njobs::Int = 0, arxiv_interval::Int = 1000,
)
    [fn(trial, npop, ngen, njobs, arxiv_interval) for trial in trange] 
end