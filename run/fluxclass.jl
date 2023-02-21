include("../src/Coevolutionary.jl")
using .Coevolutionary
using Flux
using Flux: onecold, onehotbatch, logitcrossentropy
using Flux: DataLoader
using GraphNeuralNetworks
using MLDatasets
using MLUtils
using LinearAlgebra, Random, Statistics
using JLD2
using StatsBase
using ProgressBars
using Suppressor
using Arpack

export makedataset
export makeFSMIndiv, makeGNNGraph

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

function makeFSMIndiv(spid::String, iid::String, igroup::JLD2.Group)
    makeFSMIndiv(Symbol(spid), parse(UInt32, iid), igroup)
end
function getdummyindiv()
    jl = jldopen("/media/tcw/Seagate/NewLing/comp-1.jld2")
    igroup = jl["999"]["species"]["host"]["49933"]
    :host, UInt32(49933), igroup
end

function getjl(ckey::String = "comp-1")
    jldopen("/media/tcw/Seagate/NewLing/$(ckey).jld2")
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
    ntargets = Int[]
    alias = Dict{String, UInt32}()
    i = UInt32(1)
    for s in indiv.geno.ones
        if !haskey(alias, s)
            alias[s] = i
            i += 1
        end
        push!(ntargets, 1)
    end
    for s in indiv.geno.zeros
        if !haskey(alias, s)
            alias[s] = i
            i += 1
        end
        push!(ntargets, 0)
    end

    for ((s, w), t) in indiv.geno.links
        push!(sources, alias[s])
        push!(targets, alias[t])
        push!(weights, w ? 1 : 0)
    end
    oh(x) = Float32.(onehotbatch(x, 0:1))
    GNNGraph(sources, targets, weights, ndata = (x = oh(ntargets)))
    #GNNGraph(sources, targets, ndata = (x = oh(ntargets)))
end

function makeGNNGraphs(indivs::Vector{FSMIndiv}; min::Bool = true)
    [makeGNNGraph(min ? minimize(indiv) : indiv) for indiv in indivs]
end

function minvecs(indivs::Vector{FSMIndiv})
    [minimize(indiv) for indiv in indivs]
end

# function graphspectrum(g::GNNGraph; add_self_loops = false, dir = :both)
#     lp = collect(normalized_laplacian(g, add_self_loops = add_self_loops, dir = dir))
#     println(g)
#     println(lp)
#     spec = eigvals(lp)
#     return spec
# end

function laplacian_matrix(
    g::GNNGraph, T::DataType = eltype(g); dir::Symbol = :out, add_self_loops=false
)
    A = adjacency_matrix(g, T; dir = dir)
    A = add_self_loops ? A + I : A
    D = Diagonal(vec(sum(A; dims = 2)))
    return D - A
end

function graphspectrum(g::GNNGraph; add_self_loops = false, dir = :both, usenorm::Bool = false)
    lp = usenorm ?
        normalized_laplacian(g, add_self_loops = add_self_loops, dir = dir) :
        laplacian_matrix(g, add_self_loops = add_self_loops, dir = dir)
    spec = eigvals(collect(lp))
    return spec
end

function graph_distance(g1::GNNGraph, g2::GNNGraph; add_self_loops = false, dir = :both)
    spec1 = graphspectrum(g1; add_self_loops = add_self_loops, dir = dir)
    spec2 = graphspectrum(g2; add_self_loops = add_self_loops, dir = dir)
    k = min(length(spec1), length(spec2))
    norm(spec1[1:k] - spec2[1:k])
end

function makedataset(;
    gen::Int = 999, min::Bool = true, nsample::Int = 1000,
    ckey1::String = "comp-1", spid1::Symbol = :host, iid1::Int = 1, 
    ckey2::String = "Grow-1", spid2::Symbol = :control1, iid2::Int = 1,
    add_self_loops = false, dir = :both, 
) 
    jl1 = getjl(ckey1)
    jl2 = getjl(ckey2)
    l1 = lineage(jl1, gen, spid1, iid1)
    l2 = lineage(jl2, gen, spid2, iid2)
    gs1 = makeGNNGraphs(l1; min=min)
    gs2 = makeGNNGraphs(l2; min=min)
    idxs1 = nsample == -1 ? collect(1:length(gs1)) : rand(1:length(gs1), nsample)
    idxs2 = nsample == -1 ? collect(1:length(gs1)) : rand(1:length(gs1), nsample)
    distances = Float64[]
    tgs1 = [gs1[i] for i in idxs1]
    tgs2 = [gs2[i] for i in idxs2]
    for (g1, g2) in zip(tgs1, tgs2)
        d = graph_distance(g1, g2; add_self_loops = add_self_loops, dir = dir)
        push!(distances, d)
    end
    println("done: $(ckey1) vs $(ckey2), $(spid1), $(iid1) vs $(spid2) $(iid2)")
    distances
end

function lineage(jl::JLD2.JLDFile, gen::Int, spid::Symbol, aliasid::Int)
    iid = collect(keys(jl["$(gen)"]["species"]["$(spid)"]))[aliasid + 1]
    igroup = jl["$(gen)"]["species"]["$(spid)"]["$(iid)"]
    indiv = makeFSMIndiv(spid, iid, igroup)
    pid = first(indiv.pids)
    lineage(jl, gen - 1, spid, string(pid), [indiv])
end



function makedatasetrich(;
    gen::Int = 999, min::Bool = true, nsample::Int = -1,
    ckey1::String = "comp-1", spid1::Symbol = :host, iid1::Int = 1, 
    ckey2::String = "Grow-1", spid2::Symbol = :control1, iid2::Int = 1,
) 
    jl1 = getjl(ckey1)
    jl2 = getjl(ckey2)
    l1 = lineage(jl1, gen, spid1, iid1)
    l2 = lineage(jl2, gen, spid2, iid2)
    gs1 = makeGNNGraphs(l1; min=min)
    gs2 = makeGNNGraphs(l2; min=min)
    idxs1 = nsample == -1 ? collect(1:length(gs1)) : rand(1:length(gs1), nsample)
    idxs2 = nsample == -1 ? collect(1:length(gs1)) : rand(1:length(gs1), nsample)
    idxs2 = rand(1:length(gs2), nsample)
    distances = Float64[]
    tgs1 = [gs1[i] for i in idxs1]
    tgs2 = [gs2[i] for i in idxs2]
    for (g1, g2) in zip(tgs1, tgs2)
        d = graph_distance(g1, g2, rev_spec)
        push!(distances, d)
    end
    println("done: $(ckey1) vs $(ckey2), $(spid1), $(iid1) vs $(spid2) $(iid2)")
    (tgs1, tgs2), distances
end

function grid(;eco1::String = "comp", spid1::Symbol = :host, iid1::Int = 1,
              eco2::String = "Grow", spid2::Symbol = :control1, iid2::Int = 1,
              nsample::Int = 10_000, gen::Int = 9999, min::Bool = true,
              fixtrial::Int = -1)
    sums = Float64[]
    for i in tqdm(1:50)
        ckey1 = fixtrial == -1 ? "$(eco1)-$(i)" : "$(eco1)-$(fixtrial)" 
        d = makedataset(ckey1 = ckey1, spid1 = spid1, iid1 = iid1,
                        ckey2 = "$(eco2)-$(i)", spid2 = spid2, iid2 = iid2,
                        nsample = nsample, gen = gen, min = min,)
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
