
# arguments for the `train` function 
Base.@kwdef mutable struct MyArgs
    η = 0.001             # learning rate
    batchsize = 256      # batch size (number of graphs in each batch)
    epochs = 10         # number of epochs
    seed = 42             # set seed > 0 for reproducibility
    usecuda = true      # if true use cuda (if available)
    nin = 5
    ein = 4
    d1 = 64        # dimension of hidden features
    d2 = 32        # dimension of hidden features
    dout = 16        # dimension of hidden features
    infotime = 10      # report every `infotime` epochs
    numtrain = (0.5, 0.1)
    heads = 4
    dist = "norm"
end

struct GNN                                # step 1
    conv1
    #bn1
    conv2
    #bn2
    pool
    dense1
    #bn3
    #do1
    dense2
    #bn4
    #do2
end

Flux.@functor GNN    

function GNN(nin::Int = 5, ein::Int = 4, d1::Int = 128, d2::Int = 64, dout::Int = 32, heads::Int = 4)
    GNN(
        GATv2Conv((nin, ein) => d1, add_self_loops = false, heads = heads),
        #BatchNorm(d1 * heads),
        GATv2Conv((d1 * heads, ein) => d2, add_self_loops = false, heads = heads),
        #BatchNorm(d2 * heads),
        GlobalPool(mean),
        Dense(d2 * heads, dout),
        #BatchNorm(dout),
        #Dropout(0.5),
        Dense(dout, dout),
        #BatchNorm(dout),
        #Dropout(0.5),
    )
end

function GNN(args::MyArgs)
    GNN(args.nin, args.ein, args.d1, args.d2, args.dout, args.heads)
end

function (model::GNN)(g::GNNGraph, x, e)     # step 4
    #println("1")
    x = model.conv1(g, x, e)
    #println("2")
    #x = model.bn1(x)
    x = leakyrelu.(x)
    #println("3")
    x = model.conv2(g, x, e)
    x = leakyrelu.(x)
    #x = model.bn2(x)
    #println("4")
    #x = leakyrelu.(x)
    #println("5")
    x = model.pool(g, x)
    #println("6")
    x = model.dense1(x)
    x = leakyrelu.(x)
    #x = model.bn3(x)
    #x = model.do1(x)

    x = model.dense2(x)
    # x = leakyrelu.(x)
    #x = model.bn4(x)
    #x = model.do2(x)
    #println("7")
    return x 
end

function (model::GNN)(g::GNNGraph)
    model(g, g.ndata.x, g.edata.e)
end

function my_eval_loss_accuracy(model, data_loader, device)
    loss = 0.0
    ntot = 0
    for ((g1, g2), y) in ProgressBar(data_loader)
        g1, g2, y = (g1, g2, y) |> device
        emb1 = model(g1) |> vec
        emb2 = model(g2) |> vec
        ŷ = norm(emb1 - emb2)
        loss += Flux.mse(ŷ, y)
        ntot += length(y)
    end
    return (loss = round(loss / ntot, digits = 4))
end

function mytrainloop!(
    args::MyArgs, train_loader::DataLoader, test_loader::DataLoader, model::Union{GNNChain, GNN},
    opt::ADAM, device::Function, ps::Zygote.Params
)
    function report(epoch, trainloss = nothing, testloss = nothing)
        if trainloss === nothing
            trainloss = my_eval_loss_accuracy(model, train_loader, device)
        end
        if testloss === nothing
            testloss = my_eval_loss_accuracy(model, test_loader, device)
        end
        println("Epoch: $epoch   Train: $(trainloss)   Test: $(testloss)")
    end
    #report(0)
    local training_loss
    for epoch in 1:(args.epochs)
        loss = 0.0
        ntot = 0
        for ((g1, g2), y) in ProgressBar(train_loader)
            g1, g2, y = (g1, g2, y) |> device
            gs = Flux.gradient(ps) do
                emb1 = model(g1) |> vec
                emb2 = model(g2) |> vec
                ŷ = norm(emb1 - emb2)
                training_loss = Flux.mse(ŷ, y)
            end
            loss += training_loss
            ntot += length(y)
            Flux.Optimise.update!(opt, ps, gs)
        end
        epoch % args.infotime == 0 && report(epoch, round(loss / ntot, digits = 4))
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
    dists = [pair.dists[args.dist] for pair in dataset]
    dataset = collect(zip(graphs, dists))
    train_data, test_data = splitobs(dataset, at = args.numtrain, shuffle = true)

    train_loader = DataLoader(train_data; args.batchsize, shuffle = true, collate = true)
    test_loader = DataLoader(test_data; args.batchsize, shuffle = false, collate = true)


    ps = Flux.params(model)
    opt = Adam(args.η)
    mytrainloop!(args, train_loader, test_loader, model, opt, device, ps)
end


