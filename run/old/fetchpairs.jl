struct PairResult{G1 <: FSMGraph, G2 <: FSMGraph}
    g1::G1
    g2::G2
    dist::Float64
end

#function PairResult(jargs::JobArgs)
#    g1 = FSMGraph(jargs.indiv1)
#    g2 = FSMGraph(jargs.indiv2)
#    PairResult(g1, g2, graph_distance(g1.graph, g2.graph))
#end
#
#function PairResult(indiv1::FSMIndiv, indiv2::FSMIndiv)
#    g1 = FSMGraph(indiv1)
#    g2 = FSMGraph(indiv2)
#    PairResult(g1, g2, graph_distance(g1.graph, g2.graph))
#end

function PairResult(g1::FSMGraph, g2::FSMGraph)
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

#function fetchpairs(;
#    ecos::Vector{String} = ["comp", "coop", "Grow", "Control"],
#    n::Int = 1_000,
#    seed::UInt64 = UInt64(42),
#    normdist = true,
#)
#    rng = StableRNG(seed)
#    jls = Dict((eco, trial) => getjl("$(eco)-$(trial)") for eco in ecos for trial in 1:20)
#    ecos = rand(rng, ecos, n * 2)
#    trials = rand(rng, 1:20, n * 2)
#    gens = rand(rng, 2:9999, n * 2)
#    spids = rand(rng, 1:2, n * 2)
#    iids = rand(rng, 1:50, n * 2)
#    jargs = [
#        JobArgs(
#            IndivArgs(
#                jls[(ecos[i], trials[i])], ecos[i], trials[i],
#                gens[i], spids[i], iids[i], true
#            ),
#            IndivArgs(
#                jls[(ecos[i], trials[i + 1])], ecos[i + 1], trials[i + 1],
#                gens[i + 1], spids[i + 1], iids[i + 1], true
#            ))
#        for i in 1:2:n * 2
#    ]
#    pairs = [PairResult(jarg) for jarg in jargs]
#    normdist ? normalize_distances(pairs) : pairs
#end
#
#function pfetchpairs(; 
#    ecos::Vector{String} = ["comp", "coop", "Grow", "Control"],
#    n::Int = 1_000,
#    seed::UInt64 = UInt64(42),
#    normdist = false,
#)
#    n = div(n, nprocs() - 1)
#    futures = [
#        @spawnat :any fetchpairs(ecos = ecos, n = n, seed = seed, normdist = normdist)
#        for _ in 1:nprocs() - 1
#    ]
#    reduce(vcat, [fetch(future) for future in futures])
#end

function get_pfiltered_fsmgraphs(
    eco::String, 
    trial::Int,
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    spids = keys(jld2file["arxiv/1/species"])
    pftags = Dict(
        spid => deserialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "tags", "$spid-$trial.jls"))
        for spid in spids
    )   
    archiver = FSMIndivArchiver()
    #println(pftags)
    indivs = reduce(vcat, 
        reduce(vcat, [
            reduce(vcat,[
                FSMGraph(
                    eco, 
                    trial, 
                    ftag.gen,
                    archiver(
                        ftag.spid, 
                        ftag.iid, 
                        jld2file["arxiv/$(ftag.gen)/species/$(ftag.spid)/children/$(ftag.iid)"]
                    )
                )
            for ftag in genvec])
            for genvec in pftags[spid]
        ])
        for spid in spids
    )
    println(typeof(indivs[1]))

    close(jld2file)
    indivs
end

function get_indivs(ecos::Vector{String}, trials::UnitRange{Int})
    reduce(vcat, [get_pfiltered_fsmgraphs(eco, trial) for eco in ecos, trial in trials])
end

function get_lineage(eco::String, trial::Int, spid::String)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    all_indivs = deserialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "tags", "$spid-$trial.jls"))
    gen_indivs = pop!(all_indivs)
    curr_indiv = rand(gen_indivs)
    lineage = [curr_indiv]
    while !isempty(all_indivs)
        gen_indivs = pop!(all_indivs)
        filter!(gen_indiv -> gen_indiv.currtag == curr_indiv.prevtag, gen_indivs)
        curr_indiv = rand(gen_indivs)
        push!(lineage, curr_indiv)
    end
    reverse!(lineage)
        
    archiver = FSMIndivArchiver()
    lineage = [FSMGraph(eco, trial, ftag.gen, archiver(
        ftag.spid, 
        ftag.iid, 
        jld2file["arxiv/$(ftag.gen)/species/$(ftag.spid)/children/$(ftag.iid)"]
    )) for ftag in lineage]
    close(jld2file)
    lineage
end
