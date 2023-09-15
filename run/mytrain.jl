
Base.@kwdef mutable struct MyArgs
    η = 0.001             # learning rate
    batchsize = 256      # batch size (number of graphs in each batch)
    epochs = 5         # number of epochs
    seed = 42             # set seed > 0 for reproducibility
    usecuda = true      # if true use cuda (if available)
    nin = 5
    ein = 7
    d1 = 128        # dimension of hidden features
    d2 = 64        # dimension of hidden features
    d3 = 32        # dimension of hidden features
    dout = 128        # dimension of hidden features
    infotime = 1      # report every `infotime` epochs
    numtrain = (0.9, 0.1)
    heads = 4
    do1_prob = 0.2f0
    do2_prob = 0.2f0
    do3_prob = 0.2f0
    do4_prob = 0.2f0
    do_batchnorm = true
    do_dropout = true
    dist = "raw_lower"
end

struct GNN                                # step 1
    do_batchnorm
    do_dropout
    conv1
    bn1
    do1
    conv2
    bn2
    do2
    conv3
    bn3
    do3
    pool
    dense1
    bn4
    do4
    dense2
end

Flux.@functor GNN    

function GNN(
    nin::Int, ein::Int, d1::Int, d2::Int, d3::Int, dout::Int, heads::Int, 
    do1_prob::Float32 = 0.2f0, do2_prob::Float32 = 0.2f0, 
    do3_prob::Float32 = 0.2f0, do4_prob::Float32 = 0.2f0,
    do_batchnorm::Bool = true, do_dropout::Bool = true
)
    GNN(
        do_batchnorm,
        do_dropout,
        GATv2Conv((nin, ein) => d1, add_self_loops = false, heads = heads),
        BatchNorm(d1 * heads),
        Dropout(do1_prob),
        GATv2Conv((d1 * heads, ein) => d2, add_self_loops = false, heads = heads),
        BatchNorm(d2 * heads),
        Dropout(do2_prob),
        GATv2Conv((d2 * heads, ein) => d3, add_self_loops = false, heads = heads),
        BatchNorm(d3 * heads),
        Dropout(do3_prob),
        GlobalPool(mean),
        Dense(d1 * heads + d2 * heads + d3 * heads,  dout),
        BatchNorm(dout),
        Dropout(do4_prob),
        Dense(dout, dout),
    )
end

function GNN(args::MyArgs)
    GNN(
        args.nin, args.ein, 
        args.d1, args.d2, args.d3, args.dout, args.heads, 
        args.do1_prob, args.do2_prob, args.do3_prob, args.do4_prob,
        args.do_batchnorm, args.do_dropout
    )
end

function (model::GNN)(g::GNNGraph, x, e)     # step 4
    x = model.conv1(g, x, e)
    x = model.bn1(x)
    x = leakyrelu.(x)
    if model.do_dropout
        x = model.do1(x)
    end
    k1 = x
    x = model.conv2(g, x, e)
    x = model.bn2(x)
    x = leakyrelu.(x)
    if model.do_dropout
        x = model.do2(x)
    end
    k2 = x
    x = model.conv3(g, x, e)
    x = model.bn3(x)
    x = leakyrelu.(x)
    if model.do_dropout
        x = model.do3(x)
    end
    k3 = x
    x = [k1 ; k2 ; k3]
    x = model.pool(g, x)
    x = model.dense1(x)
    x = model.bn4(x)
    x = leakyrelu.(x)
    if model.do_dropout
        x = model.do4(x)
    end
    x = model.dense2(x)
    return x 
end

function (model::GNN)(g::GNNGraph)
    model(g, g.ndata.x, g.edata.e)
end

function my_eval_loss_accuracy(model, data_loader, device, args)
    loss = 0.0
    ntot = 0
    ys = []
    ŷs = []
    for ((g1, g2), y) in ProgressBarz.ProgressBar(data_loader)
        g1, g2, y = (g1, g2, y) |> device
        emb1 = model(g1) |> vec
        emb2 = model(g2) |> vec
        emb1 = reshape(emb1, args.dout, length(y))
        emb2 = reshape(emb2, args.dout, length(y))
        y = reshape(y, 1, :)
        ŷ = pairwise_l2_norm(emb1, emb2)
        append!(ys, y)
        append!(ŷs, ŷ)
        l = Flux.mse(ŷ, y)
        loss += l
        ntot += length(y)
    end
    return (loss = round(loss, digits = 4) / ntot , total_mae = Flux.mae(ys, ŷs))
end

function pairwise_l2_norm(A::AbstractArray, B::AbstractArray)
    if size(A) != size(B)
        error("The matrices are not the same size.")
    end

    return sqrt.(sum((A .- B).^2, dims=1))
end


function mytrainloop!(
    args::MyArgs, train_loader::DataLoader, test_loader::DataLoader, model::Union{GNNChain, GNN},
    opt::ADAM, device::Function, ps::Zygote.Params
)
    function report(epoch, trainloss = nothing, testloss = nothing)
        if trainloss === nothing
            trainloss, _ = my_eval_loss_accuracy(model, train_loader, device, args)
        end
        if testloss === nothing
            testloss, testmae = my_eval_loss_accuracy(model, test_loader, device, args)
        end
        println("Epoch: $epoch   Train: $(trainloss)   Test: $(testloss)    TestMAE: $(testmae)")
    end
    #report(0)
    local training_loss
    for epoch in 1:(args.epochs)
        loss = 0.0
        ntot = 0
        for ((g1, g2), y) in ProgressBarz.ProgressBar(train_loader)
            g1, g2, y = (g1, g2, y) |> device
            gs = Flux.gradient(ps) do
                emb1 = model(g1) |> vec
                emb2 = model(g2) |> vec
                emb1 = reshape(emb1, args.dout, length(y))
                emb2 = reshape(emb2, args.dout, length(y))
                y = reshape(y, 1, :)
                ŷ = pairwise_l2_norm(emb1, emb2)
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

function train(
    dataset::Vector{GEDTrainPair}, # GEDTrainPair includes two GNNGraphs and a Dict of distances
    model::Union{GNNChain, GNN, Nothing} = nothing; # Custom GNN model
    kws... # Keyword arguments for MyArgs
)
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
    if model === nothing # Create fresh model if not provided with one
        model = GNN(args) |> device
    end

    # Create DataLoaders for train and test data
    graphs = [(pair.g1, pair.g2) for pair in dataset]
    dists = [pair.dists[args.dist] for pair in dataset] # use the distance specified in args
    dataset = collect(zip(graphs, dists))
    train_data, test_data = splitobs(dataset, at = args.numtrain, shuffle = true)
    train_loader = DataLoader(train_data; args.batchsize, shuffle = true, collate = true)
    test_loader = DataLoader(test_data; args.batchsize, shuffle = false, collate = true)
    
    # Prepare parameters and optimizer before training
    ps = Flux.params(model)
    opt = Adam(args.η)
    mytrainloop!(args, train_loader, test_loader, model, opt, device, ps)
end



@everywhere function get_dist(model, gnn1, gnn2)
    embed1 = model(gnn1 |> gpu) |> cpu
    embed2 = model(gnn2 |> gpu) |> cpu
    dist = norm(embed1 - embed2)
    return dist
end
