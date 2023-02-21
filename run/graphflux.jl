# An example of graph classification

using Flux
using Flux: onecold, onehotbatch
using Flux.Losses: logitbinarycrossentropy, mse
using Flux: DataLoader
using GraphNeuralNetworks
using MLDatasets: TUDataset
using Statistics, Random
using MLUtils
using Zygote
using CUDA
CUDA.allowscalar(false)
include("fluxclass.jl")

export MyArgs

function eval_loss_accuracy(model, data_loader, device)
    loss = 0.0
    acc = 0.0
    ntot = 0
    for (g, y) in data_loader
        g, y = (g, y) |> device
        n = length(y)
        X̂ = model(g, g.ndata.x) |> vec
        loss += logitbinarycrossentropy(ŷ, y) * n
        acc += mean((ŷ .> 0) .== y) * n
        ntot += n
    end
    return (loss = round(loss / ntot, digits = 4),
            acc = round(acc * 100 / ntot, digits = 2))
end


function getdataset()
    tudata = TUDataset("MUTAG")
    display(tudata)
    graphs = mldataset2gnngraph(tudata)
    oh(x) = Float32.(onehotbatch(x, 0:6))
    graphs = [GNNGraph(g, ndata = oh(g.ndata.targets)) for g in graphs]
    y = (1 .+ Float32.(tudata.graph_data.targets)) ./ 2
    @assert all(∈([0, 1]), y) # binary classification 
    return graphs, y
end

function makedatasetrich(;
    gen::Int = 999, min::Bool = true, nsample::Int = 1000,
    ckey1::String = "comp-1", spid1::Symbol = :host, iid1::Int = 1, 
    ckey2::String = "Grow-1", spid2::Symbol = :control1, iid2::Int = 1,
    rev_spec::Bool = false,
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
    (tgs1, tgs2), distances
end

# arguments for the `train` function 
Base.@kwdef mutable struct Args
    η = 1.0f-3             # learning rate
    batchsize = 32      # batch size (number of graphs in each batch)
    epochs = 200         # number of epochs
    seed = 42             # set seed > 0 for reproducibility
    usecuda = false      # if true use cuda (if available)
    nhidden = 128        # dimension of hidden features
    infotime = 10      # report every `infotime` epochs
end


function train(; kws...)

    args = Args(; kws...)
    args.seed > 0 && Random.seed!(args.seed)

    if args.usecuda && CUDA.functional()
        device = gpu
        args.seed > 0 && CUDA.seed!(args.seed)
        @info "Training on GPU"
    else
        device = cpu
        @info "Training on CPU"
    end

    # LOAD DATA
    NUM_TRAIN = 150

    dataset = getdataset()
    train_data, test_data = splitobs(dataset, at = NUM_TRAIN, shuffle = true)

    train_loader = DataLoader(train_data; args.batchsize, shuffle = true, collate = true)
    test_loader = DataLoader(test_data; args.batchsize, shuffle = false, collate = true)

    # DEFINE MODEL

    nin = size(dataset[1][1].ndata.x, 1)
    nhidden = args.nhidden

    model = GNNChain(GraphConv(nin => nhidden, relu),
                     GraphConv(nhidden => nhidden, relu),
                     GlobalPool(mean),
                     Dense(nhidden, 1)) |> device

    ps = Flux.params(model)
    opt = Adam(args.η)


    trainloop!(args, train_loader, test_loader, model, opt, device, ps)
end


function trainloop!(
    args::Args, train_loader::DataLoader, test_loader::DataLoader, model::GNNChain,
    opt::ADAM, device::Function, ps::Zygote.Params
)
    # LOGGING FUNCTION
    function report(epoch)
        train = eval_loss_accuracy(model, train_loader, device)
        test = eval_loss_accuracy(model, test_loader, device)
        println("Epoch: $epoch   Train: $(train)   Test: $(test)")
    end

    # TRAIN

    report(0)
    for epoch in 1:(args.epochs)
        for (g, y) in train_loader
            g, y = (g, y) |> device
            gs = Flux.gradient(ps) do
                ŷ = model(g, g.ndata.x) |> vec
                logitbinarycrossentropy(ŷ, y)
            end
            Flux.Optimise.update!(opt, ps, gs)
        end
        epoch % args.infotime == 0 && report(epoch)
    end
end

# train(; usecuda = false)
# arguments for the `train` function 
Base.@kwdef mutable struct MyArgs
    η = 1.0f-2             # learning rate
    batchsize = 10      # batch size (number of graphs in each batch)
    epochs = 500         # number of epochs
    seed = 42             # set seed > 0 for reproducibility
    usecuda = false      # if true use cuda (if available)
    nhidden1 = 64        # dimension of hidden features
    nhidden2 = 32        # dimension of hidden features
    infotime = 10      # report every `infotime` epochs
    numtrain = 100
    nsample = 200
end