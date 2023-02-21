function fetchrandgraph(;
    rng::AbstractRNG = StableRNG(rand(UInt64)),
    ecos::Vector{String} = ["Grow"],
    trials::Vector{Int} = collect(1:20),
    gens::Vector{Int} = collect(2:9999),
    min::Bool = true, datadir::String = "/home/garbus/tcw/data"
)
    eco = rand(rng, ecos)
    trial = rand(rng, trials)
    jl = getjl(string(eco, "-", trial), datadir)
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

function fetch_rgp(seed::UInt64, datadir::String)
    rng = StableRNG(seed)
    fetch_rgp(;rng = rng)
end

function fetch_rgps_parallel(rng::AbstractRNG, n::Int)
    seeds = rand(rng, UInt64, n)
    futures = [@spawnat :any fetch_rgp(seed, datadir) for seed in seeds]
    [fetch(future) for future in futures]
end

function fetch_rgps_serial(rng::AbstractRNG, n::Int)
    [fetch_rgp(rng = rng) for i in 1:n]
end
