struct IndivArgs
    eco::String
    trial::Int
    gen::Int
    spid::Int
    iid::Int
    min::Bool
end

struct JobArgs
    indiv1::IndivArgs
    indiv2::IndivArgs
end

function fetchgraph(
    ;eco::String, trial::Int, gen::Int, spid::Symbol, iid::Int, min::Bool = true
)
    jl = getjl(string(eco, "-", trial))
    allspgroup = jl["$(gen)"]["species"]
    spgroup = allspgroup[string(spid)]
    igroup = spgroup[string(iid)]
    indiv = makeFSMIndiv(spid, iid, igroup)
    makeGNNGraph(min ? minimize(indiv) : indiv)
end


function fetchrandgraph(;
    rng::AbstractRNG = StableRNG(rand(UInt64)),
    ecos::Vector{String} = ["Grow"],
    trials::Vector{Int} = collect(1:20),
    gens::Vector{Int} = collect(2:9999),
    min::Bool = true,
)
    eco = rand(rng, ecos)
    trial = rand(rng, trials)
    jl = getjl(string(eco, "-", trial))
    gen = rand(rng, gens)
    allspgroup = jl["$(gen)"]["species"]
    spid = rand(rng, keys(allspgroup))
    spgroup = allspgroup[string(spid)]
    iid = rand(rng, setdiff(keys(spgroup), Set(["popids"])))
    igroup = spgroup[string(iid)]
    indiv = makeFSMIndiv(spid, iid, igroup)
    makeGNNGraph(min ? minimize(indiv) : indiv)
end

function fetch_rgp(;
    rng::AbstractRNG = StableRNG(rand(UInt64)),
    ecos::Vector{String} = ["Grow"],
    trials::Vector{Int} = collect(1:20),
    gens::Vector{Int} = collect(2:9999),
    min = true
)
    g1 = fetchrandgraph(
        rng = rng, ecos = ecos, trials = trials, gens = gens, min = min)
    g2 = fetchrandgraph(
        rng = rng, ecos = ecos, trials = trials, gens = gens, min = min)
    (g1, g2), graph_distance(g1, g2)
end

function fetch_rgp(seed::UInt64)
    rng = StableRNG(seed)
    fetch_rgp(;rng = rng)
end

function fetchgraph(eco::String, trial::Int, gen::Int, spid::Int, iid::Int, min::Bool = true)
    jl = getjl("$(eco)-$(trial)")
    allspgroup = jl["$(gen)"]["species"]
    spid = collect(keys(allspgroup))[spid]
    spgroup = allspgroup[spid]
    iid = collect(setdiff(keys(spgroup), Set(["popids"])))[iid]
    igroup = spgroup[iid]
    indiv = makeFSMIndiv(spid, iid, igroup)
    makeGNNGraph(min ? minimize(indiv) : indiv)
end


function fetchgraph(iargs::IndivArgs)
    fetchgraph(iargs.eco, iargs.trial, iargs.gen,
        iargs.spid, iargs.iid, iargs.min)
end

function dowork(jargs::JobArgs)
    g1 = fetchgraph(jargs.indiv1)
    g2 = fetchgraph(jargs.indiv2)
    (g1, g2), graph_distance(g1, g2)
end


function doit(rng::AbstractRNG = StableRNG(rand(UInt64)), n::Int)
    gens = rand(rng, 2:9999, n * 2)
    ecos = rand(rng, ["Grow", "Control", "coop", "comp"], n * 2)
    spids = rand(rng, 1:2, n * 2)
    iids = rand(rng, 1:50, n * 2)

    futures = Vector{Future}()
    for i in 1:2:n * 2
        indiv1 = IndivArgs(ecos[i], 1, gens[i], spids[i], iids[i], true)
        indiv2 = IndivArgs(ecos[i + 1], 1, gens[i + 1], spids[i + 1], iids[i + 1], true)
        jargs = JobArgs(indiv1, indiv2)
        push!(futures, @spawnat :any dowork(jargs))
    end
    [fetch(future) for future in futures]
end

function fetch_rgps_parallel(;rng::AbstractRNG = StableRNG(rand(UInt64)), n::Int = 200)
    seeds = rand(rng, UInt64, n)
    futures = [@spawnat :any fetch_rgp(seed) for seed in seeds]
    [fetch(future) for future in futures]
end

function fetch_rgps_serial(;rng::AbstractRNG = StableRNG(rand(UInt64)), n::Int = 200)
    [fetch_rgp(rng = rng) for i in 1:n]
end
