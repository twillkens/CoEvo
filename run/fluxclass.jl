include("../src/Coevolutionary.jl")
using .Coevolutionary
using Flux
using Flux: onecold, onehotbatch, logitcrossentropy
using Flux: DataLoader
using GraphNeuralNetworks
using MLUtils
using LinearAlgebra, Random, Statistics
using JLD2
using StatsBase
using ProgressBars

export makedataset
export makeFSMIndiv, makeGNNGraph

const DATA_DIR = "/home/garbus/tcw/data"

function makeFSMIndiv(spid::Symbol, iid::UInt32, igroup::JLD2.Group)
    ones = Set(string(o) for o in igroup["ones"])
    zeros = Set(string(z) for z in igroup["zeros"])
    pids = Set(p for p in igroup["pids"])
    start = igroup["start"]
    links = Dict((string(s), w) => string(t) for (s, w, t) in igroup["links"])
    geno = FSMGeno(IndivKey(spid, iid), start, ones, zeros, links)
    FSMIndiv(geno.ikey, geno, pids)
end

function makeFSMIndiv(spid::Symbol, iid::String, igroup::JLD2.Group)
    makeFSMIndiv(spid, parse(UInt32, iid), igroup)
end

function getjl(ckey::String = "comp-1")
    jldopen("$(DATA_DIR)/$(split(ckey, "-")[1])/$(ckey).jld2")
end

function lineage(
    jl::JLD2.JLDFile, gen::Int, spid::Symbol, pid::String, indivs::Vector{FSMIndiv}
)
    if gen == 1
        return reverse(indivs)
    end
    igroup = jl["$(gen)"]["species"]["$(spid)"]["$(pid)"]
    indiv = makeFSMIndiv(spid, pid, igroup)
    push!(indivs, indiv)
    pid = first(indiv.pids)
    lineage(jl, gen - 1, spid, string(pid), indivs)
end

function lineage(jl::JLD2.JLDFile, gen::Int, spid::Symbol, aliasid::Int)
    iid = collect(keys(jl["$(gen)"]["species"]["$(spid)"]))[aliasid + 1]
    igroup = jl["$(gen)"]["species"]["$(spid)"]["$(iid)"]
    indiv = makeFSMIndiv(spid, iid, igroup)
    pid = first(indiv.pids)
    lineage(jl, gen - 1, spid, string(pid), [indiv])
end

function makeGNNGraph(indiv::FSMIndiv)
    sources = Int[]
    targets = Int[]
    weights = Int[]
    alias = Dict{String, Int}()
    i = 1

    for ((s, _), t) in indiv.geno.links
        if !haskey(alias, s)
            alias[s] = i
            i += 1
        end
        if !haskey(alias, t)
            alias[t] = i
            i += 1
        end
    end
    for ((s, w), t) in indiv.geno.links
        push!(sources, alias[s])
        push!(targets, alias[t])
        push!(weights, w)
    end
    GNNGraph(sources, targets, weights)
end

function makeGNNGraphs(indivs::Vector{FSMIndiv}; min::Bool = false)
    min ? [makeGNNGraph(minimize(indiv)) for indiv in indivs] :
          [makeGNNGraph(indiv) for indiv in indivs]
end


function minvecs(indivs::Vector{FSMIndiv})
    [minimize(indiv) for indiv in indivs]
end

function graphspectrum(g::GNNGraph)
    lp = collect(normalized_laplacian(g, add_self_loops=true, dir=:both))
    spec = eigvals(lp)
    return spec
end

function graph_distance(g1::GNNGraph, g2::GNNGraph, rev_spec::Bool = false)
    spec1 = graphspectrum(g1)
    spec2 = graphspectrum(g2)
    k = min(length(spec1), length(spec2))
    rev_spec ? norm(reverse(spec1[1:k]) - reverse(spec2[1:k])) :
               norm(spec1[1:k] - spec2[1:k])
end

function makedataset(;
    gen::Int = 999, min::Bool = true, nsample::Int = 1000,
    ckey1::String = "comp-1", spid1::Symbol = :host, iid1::Int = 1, 
    ckey2::String = "Grow-1", spid2::Symbol = :control1, iid2::Int = 1,
    rev_spec::Bool = false, sumdist::Bool = true
) 
    jl1 = getjl(ckey1)
    jl2 = getjl(ckey2)
    l1 = lineage(jl1, gen, spid1, iid1)
    l2 = lineage(jl2, gen, spid2, iid2)
    gs1 = makeGNNGraphs(l1; min=min)
    gs2 = makeGNNGraphs(l2; min=min)
    idxs1 = rand(1:length(gs1), nsample)
    idxs2 = rand(1:length(gs2), nsample)
    distances = Float64[]
    tgs1 = [gs1[i] for i in idxs1]
    tgs2 = [gs2[i] for i in idxs2]
    for (g1, g2) in zip(tgs1, tgs2)
        d = graph_distance(g1, g2, rev_spec)
        push!(distances, d)
    end
    println("done: $(ckey1) vs $(ckey2), $(spid1), $(iid1) vs $(spid2) $(iid2)")
    sumdist ? sum(distances) : distances
end

function grid(;eco1::String = "comp", spid1::Symbol = :host, iid1::Int = 1,
              eco2::String = "Grow", spid2::Symbol = :control1, iid2::Int = 1,
              nsample::Int = 1000, gen::Int = 999, min::Bool = true, rev_spec::Bool = false,
              fixtrial::Int = -1, trange::UnitRange = 1:20)
    sums = Float64[]
    for i in tqdm(trange)
        ckey1 = fixtrial == -1 ? "$(eco1)-$(i)" : "$(eco1)-$(fixtrial)" 
        d = makedataset(ckey1 = ckey1, spid1 = spid1, iid1 = iid1,
                        ckey2 = "$(eco2)-$(i)", spid2 = spid2, iid2 = iid2,
                        nsample = nsample, gen = gen, min = min, rev_spec = rev_spec)
        push!(sums, sum(d))
        println(sum(sums), mean(sums), std(sums))
    end
    sum(sums), mean(sums), std(sums)
end

Base.@kwdef struct JLArgs
    ckey::String
    spid::Symbol
    iid::Int
end

Base.@kwdef struct DatasetArgs
    jl1::JLArgs
    jl2::JLArgs
    nsample::Int
    gen::Int
    min::Bool
    rev_spec::Bool
    sumdist::Bool
end

function makedataset(dargs::DatasetArgs)
    makedataset(;
    ckey1 = dargs.jl1.ckey, spid1 = dargs.jl1.spid, iid1 = dargs.jl1.iid,
    ckey2 = dargs.jl2.ckey, spid2 = dargs.jl2.spid, iid2 = dargs.jl2.iid,
    nsample = dargs.nsample, gen = dargs.gen, min = dargs.min, rev_spec = dargs.rev_spec,
    sumdist = dargs.sumdist)
end
