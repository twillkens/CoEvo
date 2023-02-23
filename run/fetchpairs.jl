struct IndivArgs
    jl::JLD2.JLDFile
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

struct FSMGNNGraph
    eco::String
    trial::String
    gen::String
    spid::String
    iid::String
    graph::GNNGraph
end

function fetchgraph(jl::JLD2.JLDFile, gen::Int, spid::Int, iid::Int, min::Bool = true)
    allspgroup = jl["$(gen)"]["species"]
    spid = collect(keys(allspgroup))[spid]
    spgroup = allspgroup[spid]
    iid = collect(setdiff(keys(spgroup), Set(["popids"])))[iid]
    igroup = spgroup[iid]
    indiv = makeFSMIndiv(spid, iid, igroup)
    makeGNNGraph(min ? minimize(indiv) : indiv)
end

function fetchgraph(iargs::IndivArgs)
    graph = fetchgraph(iargs.jl, iargs.gen, iargs.spid, iargs.iid, iargs.min)
    FSMGNNGraph(
        iargs.eco, string(iargs.trial), string(iargs.gen),
        string(iargs.spid), string(iargs.iid), graph
    )
end

struct PairResult{G1 <: FSMGNNGraph, G2 <: FSMGNNGraph}
    g1::G1
    g2::G2
    dist::Float64
end

function fetchpair(jargs::JobArgs)
    g1 = fetchgraph(jargs.indiv1)
    g2 = fetchgraph(jargs.indiv2)
    PairResult(g1, g2, graph_distance(g1.graph, g2.graph))
end

function filterpairs(prs::Vector{<:PairResult}, n::Int = 2)
    filter(
        pr -> 
        pr.g1.graph.num_nodes >= n && 
        pr.g2.graph.num_nodes >= n,
        prs
    )
end

function normalizepairs(pairs::Vector{<:PairResult})
    dists = [pr.dist for pr in pairs]
    maxdist = maximum(dists)
    mindist = minimum(dists)
    [PairResult(pr.g1, pr.g2, (pr.dist - mindist) / (maxdist - mindist)) for pr in pairs]
end

function fetchpairs(;
    ecos::Vector{String} = ["comp", "coop", "Grow", "Control"],
    n::Int = 1_000,
    seed::UInt64 = UInt64(42),
    sizefilter::Int = 2,
)
    rng = StableRNG(seed)
    jls = Dict((eco, trial) => getjl("$(eco)-$(trial)") for eco in ecos for trial in 1:20)
    ecos = rand(rng, ecos, n * 2)
    trials = rand(rng, 1:20, n * 2)
    gens = rand(rng, 2:9999, n * 2)
    spids = rand(rng, 1:2, n * 2)
    iids = rand(rng, 1:50, n * 2)
    jargs = [
        JobArgs(
            IndivArgs(
                jls[(ecos[i], trials[i])], ecos[i], trials[i],
                gens[i], spids[i], iids[i], true
            ),
            IndivArgs(
                jls[(ecos[i], trials[i + 1])], ecos[i + 1], trials[i + 1],
                gens[i + 1], spids[i + 1], iids[i + 1], true
            ))
        for i in 1:2:n * 2
    ]
    pairs = [fetchpair(jarg) for jarg in jargs]
    sizefilter == -1 ? pairs : filterpairs(pairs, sizefilter)
end

function pfetchpairs(; 
    ecos::Vector{String} = ["comp", "coop", "Grow", "Control"],
    n::Int = 1_000,
    seed::UInt64 = UInt64(42),
    sizefilter::Int = 2,
)
    n = div(n, nprocs() - 1)
    futures = [
        @spawnat :any fetchpairs(ecos = ecos, n = n, seed = seed, sizefilter = sizefilter)
        for _ in 1:nprocs() - 1
    ]
    reduce(vcat, [fetch(future) for future in futures])
end