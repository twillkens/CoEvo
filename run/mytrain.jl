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

function my_eval_loss_accuracy(model, data_loader, device)
    loss = 0.0
    ntot = 0
    for ((g1, g2), y) in data_loader
        g1, g2, y = (g1, g2, y) |> device
        n = length(y)
        emb1 = model(g1, g1.ndata.x) |> vec
        emb2 = model(g2, g2.ndata.x) |> vec
        ŷ = norm(emb1 - emb2, 1)
        loss += mse(ŷ, y) * n
        ntot += n
    end
    return (loss = round(loss / ntot, digits = 4))
            
end

function makemodel(nin, nhidden1, nhidden2, device)
    model = GNNChain(GraphConv(nin => nhidden1, relu),
                     GraphConv(nhidden1 => nhidden2, relu),
                     GlobalPool(mean)) |> device
end
# train(; usecuda = false)
# arguments for the `train` function 
Base.@kwdef mutable struct MyArgs
    η = 1.0f-2             # learning rate
    batchsize = 10      # batch size (number of graphs in each batch)
    epochs = 500         # number of epochs
    seed = 42             # set seed > 0 for reproducibility
    usecuda = false      # if true use cuda (if available)
    nhidden1 = 128        # dimension of hidden features
    nhidden2 = 64        # dimension of hidden features
    infotime = 10      # report every `infotime` epochs
    numtrain = 5000
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

function mytrain(dataset; kws...)
    args = MyArgs(; kws...)
    args.seed > 0 && Random.seed!(args.seed)

    if args.usecuda && CUDA.functional()
        device = gpu
        args.seed > 0 && CUDA.seed!(args.seed)
        @info "Training on GPU"
    else
        device = cpu
        @info "Training on CPU"
    end

    nin::Int = 0
    try
        nin = size(dataset[1][1][1].ndata.x, 1)
    catch
        nin = size(dataset[1][1].ndata.x, 1)
    end
    # LOAD DATA
    train_data, test_data = splitobs(dataset, at = args.numtrain, shuffle = true)

    train_loader = DataLoader(train_data; args.batchsize, shuffle = true, collate = true)
    test_loader = DataLoader(test_data; args.batchsize, shuffle = false, collate = true)

    model = GNNChain(GraphConv(nin => args.nhidden1, relu),
                     GraphConv(args.nhidden1 => args.nhidden2, relu),
                     GlobalPool(mean)) |> device

    ps = Flux.params(model)
    opt = Adam(args.η)
    mytrainloop!(args, train_loader, test_loader, model, opt, device, ps)
end


function mytrainloop!(
    args::MyArgs, train_loader::DataLoader, test_loader::DataLoader, model::GNNChain,
    opt::ADAM, device::Function, ps::Zygote.Params
)
    function report(epoch)
        train = my_eval_loss_accuracy(model, train_loader, device)
        test = my_eval_loss_accuracy(model, test_loader, device)
        println("Epoch: $epoch   Train: $(train)   Test: $(test)")
    end

    report(0)
    for epoch in 1:(args.epochs)
        for ((g1, g2), y) in train_loader
            g1, g2, y = (g1, g2, y) |> device
            gs = Flux.gradient(ps) do
                emb1 = model(g1, g1.ndata.x) |> vec
                emb2 = model(g2, g2.ndata.x) |> vec
                ŷ = norm(emb1 - emb2, 1)
                mse(ŷ, y)
            end
            Flux.Optimise.update!(opt, ps, gs)
        end
        epoch % args.infotime == 0 && report(epoch)
    end
    model
end
