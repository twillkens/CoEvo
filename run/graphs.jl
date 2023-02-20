using CSV
using DataFrames
using JLD2

struct CSVFileHub
    graph_labels::IOStream
    node_labels::IOStream
    graph_indicator::IOStream
    A::IOStream
    edge_labels::IOStream
end

function CSVFileHub(dname::String)
    rm(dname, force=true, recursive=true)
    mkdir(dname)
    CSVFileHub(
        open("$(dname)/$(dname)_graph_labels.txt", "a"),
        open("$(dname)/$(dname)_node_labels.txt", "a"),
        open("$(dname)/$(dname)_graph_indicator.txt", "a"),
        open("$(dname)/$(dname)_A.txt", "a"),
        open("$(dname)/$(dname)_edge_labels.txt", "a"),
    )
end

Base.@kwdef mutable struct GraphState
    nodeid::Int = 1
    graphid::Int = 1
    graphlabel::Int = 1
end


function write!(
    fhub::CSVFileHub,
    graph_labels::Vector{Int}, node_labels::Vector{Int}, graph_indicator::Vector{Int}, 
    sources::Vector{Int}, targets::Vector{Int}, edge_labels::Vector{Int}
)
    [println(fhub.graph_labels, gl) for gl in graph_labels]
    [println(fhub.node_labels, nl) for nl in node_labels]
    [println(fhub.graph_indicator, gi) for gi in graph_indicator]
    [println(fhub.A, "$(s), $(t)") for (s, t) in zip(sources, targets)]
    [println(fhub.edge_labels, el) for el in edge_labels]
end

function logindiv(gstate::GraphState, fhub::CSVFileHub, igroup::JLD2.Group)
    graph_label = Int[gstate.graphlabel]
    graph_indicator = Int[]
    node_labels = Int[]
    sources = Int[]
    targets = Int[]
    edge_labels = Int[]

    start = parse(UInt32, igroup["start"])
    node_id_dict = Dict{UInt32, Int}()
    for one in igroup["ones"]
        node_id_dict[one] = gstate.nodeid
        push!(graph_indicator, gstate.graphid)
        if one != start
            push!(node_labels, 1)
        else
            push!(node_labels, 2)
        end
        gstate.nodeid += 1
    end
    for zero in igroup["zeros"]
        node_id_dict[zero] = gstate.nodeid
        push!(graph_indicator, gstate.graphid)
        if zero != start
            push!(node_labels, 3)
        else
            push!(node_labels, 4)
        end
        gstate.nodeid += 1
    end
    for (origin, bool, destination) in igroup["links"]
        push!(sources, node_id_dict[origin])
        push!(targets, node_id_dict[destination])
        push!(edge_labels, bool)
    end
    write!(fhub, graph_label, node_labels, graph_indicator, sources, targets, edge_labels)
    gstate.graphid += 1
end


function makecsvs(gstate::GraphState, fhub::CSVFileHub, gengroup::JLD2.Group, gen::Int)
    println(gen)
    allspgroup = gengroup["species"]
    for spkey in keys(allspgroup)
        spgroup = allspgroup[spkey]
        for iid in filter(k -> k != "popids", keys(spgroup))
            igroup = spgroup[iid]
            logindiv(gstate, fhub, igroup)
        end
    end
end

function makecsvs(gstate::GraphState, fhub::CSVFileHub, jld::JLD2.JLDFile, genrange::StepRange{Int64, Int64})
    [makecsvs(gstate, fhub, jld["$(i)"], i) for i in genrange]
end


function controlcsvs(
    dname::String = "COMPGROW",
    path1::String = "/media/tcw/Seagate/NewLing/comp-1.jld2",
    path2::String = "/media/tcw/Seagate/NewLing/Grow-1.jld2",
)
    fhub = CSVFileHub(dname)
    gstate = GraphState()
    jld1 = jldopen(path1)
    makecsvs(gstate, fhub, jld1, 1:1000:10_000)
    println("done 1")
    gstate.graphlabel += 1
    jld2 = jldopen(path2)
    makecsvs(gstate, fhub, jld2, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-2.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-3.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-4.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-5.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-6.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-7.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-8.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-9.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    jld = jldopen("/media/tcw/Seagate/NewLing/Grow-10.jld2")
    makecsvs(gstate, fhub, jld, 1:1000:10_000)
    println("done")
end

controlcsvs()

# function makecsvs(logs::Vector{OrgLog}, gdf::GraphDF, trial::Int)
#     for (i, log) in enumerate(logs)
#         if i in 1:50
#             graph_label = cantor(1, trial)
#         elseif i in 51:100
#             graph_label = cantor(2, trial)
#         else
#             graph_label = cantor(3, trial) 
#         end
#         append!(gdf.graph_labels, Dict("label" => graph_label))
#         node_id_dict = Dict{Float32, Int}()
#         for node in log.graph.neuron_pos
#             node_id_dict[node] = gdf.nodeid
#             append!(gdf.graph_indicator, Dict("graph_id" => gdf.graphid))
#             if node == -2.0f0
#                 nodelabel = 1
#             elseif node == -1.0f0
#                 nodelabel = 2
#             elseif node == -0.0f0
#                 nodelabel = 3
#             elseif node == 1.0f0
#                 nodelabel = 4
#             elseif node == 2.0f0
#                 nodelabel = 5
#             else
#                 nodelabel = 6
#             end
#             append!(gdf.node_labels, Dict("category" => nodelabel))
#             gdf.nodeid += 1
#         end
#         for g in log.graph.genes
#             origin = node_id_dict[g.origin]
#             destination = node_id_dict[g.destination]
#             append!(gdf.A, Dict("source" => origin, "target" => destination))
#             append!(gdf.edge_labels, Dict("weight" => g.weight))
#         end
#         gdf.graphid += 1
#     end
# end
# 
# function makeallcsvs(eco::String)
#     nodeid = 1
#     graphid = 1
#     graph_labels = DataFrame(Dict(["label" => Int[]]))
#     graph_indicator = DataFrame(Dict(["graph_id" => Int[]]))
#     node_labels = DataFrame(Dict(["category" => Int[]]))
#     A = DataFrame(Dict("source" => Int[], "target" => Int[]))
#     edge_labels = DataFrame(Dict(["weight" => Float32[]]))
#     gdf = GraphDF(nodeid,
#                   graphid,
#                   graph_labels,
#                   graph_indicator,
#                   node_labels,
#                   A,
#                   edge_labels)
#     for i in 2:20
#         logs = deserialize("triallogs/$(eco)/trial-$(i).jls")
#         makecsvs(logs, gdf, i)
#     end
#     CSV.write("COLLISION/COLLISION_node_labels.txt", gdf.node_labels, header=false)
#     CSV.write("COLLISION/COLLISION_graph_indicator.txt", gdf.graph_indicator, header=false)
#     CSV.write("COLLISION/COLLISION_graph_labels.txt", gdf.graph_labels, header=false)
#     CSV.write("COLLISION/COLLISION_A.txt", gdf.A, header=false)
#     CSV.write("COLLISION/COLLISION_edge_labels.txt", gdf.edge_labels, header=false)
# end