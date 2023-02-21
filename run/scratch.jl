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
        d = graph_distance(g1, g2, false)
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

function mytrain(; kws...)
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

    # LOAD DATA
    dataset = getproteins(args.nsample)
    train_data, test_data = splitobs(dataset, at = args.numtrain, shuffle = true)

    train_loader = DataLoader(train_data; args.batchsize, shuffle = true, collate = true)
    test_loader = DataLoader(test_data; args.batchsize, shuffle = false, collate = true)

    nin = size(dataset[1][1][1].ndata.x, 1)
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
    # LOGGING FUNCTION
    function report(epoch)
        train = my_eval_loss_accuracy(model, train_loader, device)
        test = my_eval_loss_accuracy(model, test_loader, device)
        println("Epoch: $epoch   Train: $(train)   Test: $(test)")
    end

    # TRAIN

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

function Graphs.laplacian_matrix(g::GNNGraph, T::DataType = eltype(g); dir::Symbol = :out)
    A = adjacency_matrix(g, T; dir = dir)
    D = Diagonal(vec(sum(A; dims = 2)))
    return D - A
end