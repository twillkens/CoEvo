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

struct FSMGraph{G <: GNNGraph, I <: FSMIndiv}
    eco::String
    trial::String
    gen::String
    spid::String
    iid::String
    graph::G
    indiv::I
end

function makeGNNGraph(indiv::FSMIndiv, domin::Bool = true)
    #allnodes = union(indiv.geno.ones, indiv.geno.zeros)
    allnodes = domin ? 
        union(indiv.mingeno.ones, indiv.mingeno.zeros) :
        union(indiv.geno.ones, indiv.geno.zeros) 
    links = domin ? indiv.mingeno.links : indiv.geno.links
    aliasd = Dict(node => alias for (node, alias) in zip(allnodes, 1:length(allnodes)))
    links = [aliasd[s] => aliasd[t] for ((s, _), t) in links]
    #to_bidirected(remove_self_loops(GNNGraph(
    #    [link[1] for link in links],
    #    [link[2] for link in links],
    #    ndata = (x = ones(1, length(allnodes)))
    #)))
    to_bidirected(GNNGraph(
        [link[1] for link in links],
        [link[2] for link in links],
        ndata = (x = ones(1, length(allnodes))
    )))
end

function makeGNNGraph(jl::JLD2.JLDFile, gen::Int, spid::Int, iid::Int, min::Bool = true)
    allspgroup = jl["$(gen)"]["species"]
    spid = collect(keys(allspgroup))[spid]
    spgroup = allspgroup[spid]
    iid = collect(setdiff(keys(spgroup), Set(["popids"])))[iid]
    igroup = spgroup[iid]
    indiv = makeFSMIndiv(spid, iid, igroup)
    makeGNNGraph(min ? minimize(indiv) : indiv)
end

#function FSMGraph(iargs::IndivArgs)
#    FSMGraph(
#        iargs.eco, string(iargs.trial), string(iargs.gen),
#        string(iargs.spid), string(iargs.iid), 
#        makeGNNGraph(iargs.jl, iargs.gen, iargs.spid, iargs.iid, iargs.min)
#    )
#end

function FSMGraph(eco::String, trial::Int, gen::Int, indiv::FSMIndiv)
    FSMGraph(
        eco,
        string(trial),
        string(gen),
        string(indiv.ikey.spid),
        string(indiv.ikey.iid),
        makeGNNGraph(indiv),
        indiv
    )
end