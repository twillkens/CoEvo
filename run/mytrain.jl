
# arguments for the `train` function 
Base.@kwdef mutable struct MyArgs
    η = 0.001             # learning rate
    batchsize = 256      # batch size (number of graphs in each batch)
    epochs = 100         # number of epochs
    seed = 42             # set seed > 0 for reproducibility
    usecuda = true      # if true use cuda (if available)
    nin = 5
    ein = 4
    d1 = 128        # dimension of hidden features
    d2 = 64        # dimension of hidden features
    dout = 32        # dimension of hidden features
    infotime = 10      # report every `infotime` epochs
    numtrain = (0.5, 0.05)
    heads = 4
end

struct GNN                                # step 1
    conv1
    bn
    conv2
    dropout
    dense
    pool
end

Flux.@functor GNN    

function GNN(nin::Int = 5, ein::Int = 4, d1::Int = 128, d2::Int = 64, dout::Int = 32, heads::Int = 4)
    #nin = nin * heads
    #ein = ein * heads
    #d1 = d1 * heads
    #d2 = d2 * heads
    GNN(
        GATv2Conv((nin, ein) => d1 * heads, add_self_loops = false, heads = heads),
        #GATv2Conv(nin => d1, add_self_loops = false),
        BatchNorm(d1),
        # GATv2Conv(d1 => d2, add_self_loops = false),
        GATv2Conv((d1 * heads * 2, ein) => d2, add_self_loops = false, heads = heads),
        Dropout(0.5),
        Dense(d2 * heads, dout),
        GlobalPool(mean),
    )
end

function GNN(args::MyArgs)
    GNN(args.nin, args.ein, args.d1, args.d2, args.dout, args.heads)
end

function (model::GNN)(g::GNNGraph, x, e)     # step 4
    x = model.conv1(g, x, e)
    x = leakyrelu.(x)
    x = model.conv2(g, x, e)
    x = leakyrelu.(x)
    x = model.pool(g, x)
    x = model.dense(x)
    return x 
end

function (model::GNN)(g::GNNGraph)
    model(g, g.ndata.x, g.edata.e)
end

function my_eval_loss_accuracy(model, data_loader, device)
    loss = 0.0
    ntot = 0
    for ((g1, g2), y) in data_loader
        g1, g2, y = (g1, g2, y) |> device
        n = length(y)
        emb1 = model(g1) |> vec
        emb2 = model(g2) |> vec
        #emb1 = reshape(model(g1), :)  # replace vec with reshape
        #emb2 = reshape(model(g2), :)  # replace vec with reshape
        ŷ = norm(emb1 - emb2)
        loss += Flux.mse(ŷ, y)
        ntot += n
    end
    return (loss = round(loss / ntot, digits = 4))
end

function mytrainloop!(
    args::MyArgs, train_loader::DataLoader, test_loader::DataLoader, model::Union{GNNChain, GNN},
    opt::ADAM, device::Function, ps::Zygote.Params
)
    function report(epoch)
        train = my_eval_loss_accuracy(model, train_loader, device)
        test = my_eval_loss_accuracy(model, test_loader, device)
        println("Epoch: $epoch   Train: $(train)   Test: $(test)")
    end
    report(0)
    for epoch in 1:(args.epochs)
        for ((g1, g2), y) in ProgressBar(train_loader)
            g1, g2, y = (g1, g2, y) |> device
            gs = Flux.gradient(ps) do
                emb1 = model(g1) |> vec
                emb2 = model(g2) |> vec
                #emb1 = reshape(model(g1), :)  # replace vec with reshape
                #emb2 = reshape(model(g2), :)  # replace vec with reshape
                ŷ = norm(emb1 - emb2)
                Flux.mse(ŷ, y)
            end
            Flux.Optimise.update!(opt, ps, gs)
        end
        epoch % args.infotime == 0 && report(epoch)
    end
    model
end

function mytrain(dataset::Vector{GEDTrainPair}, model::Union{GNNChain, GNN, Nothing} = nothing; kws...)
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
    if model === nothing
        model = GNN(args) |> device
    end

    # LOAD DATA
    graphs = [(pair.g1, pair.g2) for pair in dataset]
    dists = [pair.normdist for pair in dataset]
    dataset = collect(zip(graphs, dists))
    train_data, test_data = splitobs(dataset, at = args.numtrain, shuffle = true)

    train_loader = DataLoader(train_data; args.batchsize, shuffle = true, collate = true)
    test_loader = DataLoader(test_data; args.batchsize, shuffle = false, collate = true)


    ps = Flux.params(model)
    opt = Adam(args.η)
    mytrainloop!(args, train_loader, test_loader, model, opt, device, ps)
end


