
vec_to_matrix(X) = mapreduce(permutedims, vcat, [X[i][:,1] for i in 1:length(X)])


function plotlineage(model::GNNChain, l::Vector{<:GNNGraph},)
    X = [model(g, g.ndata.x) |> cpu for g in l |> cpu]
    Xtr = mapreduce(permutedims, vcat, [X[i][:,1] for i in eachindex(X)])
    M = fit(PCA, Xtr; maxoutdim=2)
    scatter(M[1], M[2], legend=false)
end

function plotlineage(model::GNNChain, l::Vector{<:FSMIndiv})
    lgs = [makeGNNGraph(i) for i in l]
    plotlineage(model,lgs,)
end


function testdoit(nsample::Int = 1_000, ntrain::Int = 500)
    jld = jldopen("test.jld2", "w")
    pairs = pfetchpairs(;n = nsample, ecos = ["coop", "comp", "Grow", "Control"])
    jld["pairs"] = pairs
    model = mytrain(pairs; numtrain=ntrain)
    jld["model"] = model
    l = lineage("comp-1", 9999, :host, 1)
    fsms = [FSMGraph("comp", 1, gen, i) for (gen, i) in enumerate(l)]
    jld["fsms"] = fsms

    graphs = [
        map(fsm -> fsm.graph, fsms);
        map(pair -> pair.g1.graph, pairs);
        map(pair -> pair.g2.graph, pairs)
    ]
    embs = []
    for (i, g) in enumerate(graphs)
        g = g |> cpu
        emb = model(g, g.ndata.x) |> vec
        push!(embs, emb)
    end

    X = [model(g, g.ndata.x) |> cpu for g in graphs |> gpu]
    Xtr = vec_to_matrix(X)
    M = fit(PCA, Xtr; maxoutdim=2)
    jld["M"] = M
    p = scatter(M.proj[1:9999, :])
    savefig(p, "test.png")
    close(jld)
end

function doit2(nsample::Int = 1_000, ntrain::Int = 500)
    #jld = jldopen("test.jld2", "w")
    indivs = get_indivs(["comp", "coop", "ctrl"], 1:5)
    filter(indiv -> length(union(indiv.indiv.mingeno.ones, indiv.indiv.mingeno.zeros)) > 1, indivs)
    println(typeof(indivs[1]))
    pairidxs1 = rand(1:length(indivs), nsample)
    pairidxs2 = rand(1:length(indivs), nsample)
    pairs = [
        PairResult(indivs[i], indivs[j]) 
        for (i, j) in zip(pairidxs1, pairidxs2)
    ]
    #jld["pairs"] = pairs
    model = mytrain(pairs; numtrain=ntrain)
    #jld["model"] = model
    lineage_fsms = get_lineage("comp", 1, "host")
    println(length(lineage_fsms))

    #jld["fsms"] = fsms

    graphs = [
        map(fsm -> fsm.graph, lineage_fsms);
        map(pair -> pair.g1.graph, pairs);
        map(pair -> pair.g2.graph, pairs)
    ]
    #embs = []
    #for (i, g) in enumerate(graphs)
    #    g = Flux.batch([g]) |> gpu
    #    emb = model(g, g.ndata.x) |> vec |> cpu
    #    println(emb)
    #    push!(embs, emb)
    #end

    #bs = Flux.batch(graphs) |> gpu
    #embs = model(bs, bs.ndata.x) |> vec |> cpu
    #println(embs)

    X = [model(g, g.ndata.x) |> vec |> cpu for g in graphs |> gpu]
    Xtr = vec_to_matrix(X)
    return Xtr
    #M = fit(PCA, Xtr; maxoutdim=2)
    ##jld["M"] = M
    #p = scatter(M.proj[1:2000, :])
    #savefig(p, "test.png")
    #close(jld)
end
function get_gnngraph_proteins()
    tudata = TUDataset("PROTEINS")
    display(tudata)
    graphs = mldataset2gnngraph(tudata)
    l = length(graphs[1].ndata.targets)
    oh(x) = Float32.(onehotbatch(x, 0:l - 1))
    graphs = [GNNGraph(g, ndata = oh(g.ndata.targets)) for g in graphs]
end

function getproteins(nsample::Int)
    tudata = TUDataset("PROTEINS")
    display(tudata)
    graphs = mldataset2gnngraph(tudata)
    l = length(graphs[1].ndata.targets)
    oh(x) = Float32.(onehotbatch(x, 0:l - 1))
    graphs = [GNNGraph(g, ndata = oh(g.ndata.targets)) for g in graphs]
    idxs1 = rand(1:length(graphs), nsample)
    idxs2 = rand(1:length(graphs), nsample)
    distances = Float64[]
    tgs1 = [graphs[i] for i in idxs1]
    tgs2 = [graphs[i] for i in idxs2]
    for (g1, g2) in zip(tgs1, tgs2)
        d = graph_distance(g1, g2)
        push!(distances, d)
    end
    return (tgs1, tgs2), distances
end


function testembed()
    model = makemodel(42, 64, 32, cpu)
    graphs = get_gnngraph_proteins()
    g1s, g2s = graphs[1:100], graphs[101:200]
    b1, b2 = Flux.batch(g1s), Flux.batch(g2s)
    e1s, e2s = model(b1, b1.ndata.x), model(b2, b2.ndata.x)
    e1s, e2s, norm(e1s - e2s)
end

function testgraphdist()
    graphs = get_gnngraph_proteins()
    g1s, g2s = graphs[1:100], graphs[101:200]
    dists = [graph_distance(g1, g2) for (g1, g2) in zip(g1s, g2s)]
end