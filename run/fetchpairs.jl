struct PairResult{G1 <: FSMGraph, G2 <: FSMGraph}
    g1::G1
    g2::G2
    dist::Float64
end

function PairResult(jargs::JobArgs)
    g1 = FSMGraph(jargs.indiv1)
    g2 = FSMGraph(jargs.indiv2)
    PairResult(g1, g2, graph_distance(g1.graph, g2.graph))
end

function normalize_distances(pairs::Vector{<:PairResult})
    dists = [pr.dist for pr in pairs]
    dt = fit(UnitRangeTransform, dists)
    [
        PairResult(pr.g1, pr.g2, normdist)
        for (pr, normdist) in zip(pairs, StatsBase.transform(dt, dists))
    ]
end

function fetchpairs(;
    ecos::Vector{String} = ["comp", "coop", "Grow", "Control"],
    n::Int = 1_000,
    seed::UInt64 = UInt64(42),
    normdist = true,
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
    pairs = [PairResult(jarg) for jarg in jargs]
    normdist ? normalize_distances(pairs) : pairs
end

function pfetchpairs(; 
    ecos::Vector{String} = ["comp", "coop", "Grow", "Control"],
    n::Int = 1_000,
    seed::UInt64 = UInt64(42),
)
    n = div(n, nprocs() - 1)
    futures = [
        @spawnat :any fetchpairs(ecos = ecos, n = n, seed = seed)
        for _ in 1:nprocs() - 1
    ]
    reduce(vcat, [fetch(future) for future in futures])
end