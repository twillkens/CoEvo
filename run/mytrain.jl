
# arguments for the `train` function 
Base.@kwdef mutable struct MyArgs
    η = 0.001             # learning rate
    batchsize = 256      # batch size (number of graphs in each batch)
    epochs = 30         # number of epochs
    seed = 42             # set seed > 0 for reproducibility
    usecuda = true      # if true use cuda (if available)
    nin = 5
    ein = 7
    d1 = 256        # dimension of hidden features
    d2 = 128        # dimension of hidden features
    d3 = 64        # dimension of hidden features
    dout = 256        # dimension of hidden features
    infotime = 1      # report every `infotime` epochs
    numtrain = (0.5, 0.1)
    heads = 4
    dist = "raw"
end

struct GNN                                # step 1
    conv1
    bn1
    conv2
    bn2
    conv3
    bn3
    pool
    dense1
    bn4
    dense2
end

Flux.@functor GNN    

function GNN(nin::Int, ein::Int, d1::Int, d2::Int, d3::Int, dout::Int, heads::Int)
    GNN(
        GATv2Conv((nin, ein) => d1, add_self_loops = false, heads = heads),
        BatchNorm(d1 * heads),
        GATv2Conv((d1 * heads, ein) => d2, add_self_loops = false, heads = heads),
        BatchNorm(d2 * heads),
        GATv2Conv((d2 * heads, ein) => d3, add_self_loops = false, heads = heads),
        BatchNorm(d3 * heads),
        GlobalPool(mean),
        Dense(d1 * heads + d2 * heads + d3 * heads,  dout),
        BatchNorm(dout),
        Dense(dout, dout),
    )
end

function GNN(args::MyArgs)
    GNN(args.nin, args.ein, args.d1, args.d2, args.d3, args.dout, args.heads)
end

function (model::GNN)(g::GNNGraph, x, e)     # step 4
    x = model.conv1(g, x, e)
    x = model.bn1(x)
    x = leakyrelu.(x)
    k1 = x
    x = model.conv2(g, x, e)
    x = model.bn2(x)
    x = leakyrelu.(x)
    k2 = x
    x = model.conv3(g, x, e)
    x = model.bn3(x)
    x = leakyrelu.(x)
    k3 = x
    #p1 = model.pool(g, k1)
    #p2 = model.pool(g, k2)
    #p3 = model.pool(g, k3)
    #x = [p1 ; p2 ; p3]
    x = [k1 ; k2 ; k3]
    x = model.pool(g, x)
    x = model.dense1(x)
    x = model.bn4(x)
    x = leakyrelu.(x)
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
    for ((g1, g2), y) in ProgressBar(data_loader)
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
    local embed1
    local embed2
    local y_hat
    local y_bald
    for epoch in 1:(args.epochs)
        loss = 0.0
        ntot = 0
        for ((g1, g2), y) in ProgressBar(train_loader)
            g1, g2, y = (g1, g2, y) |> device
            gs = Flux.gradient(ps) do
                emb1 = model(g1) |> vec
                emb2 = model(g2) |> vec
                emb1 = reshape(emb1, args.dout, length(y))
                emb2 = reshape(emb2, args.dout, length(y))
                y = reshape(y, 1, :)
                ŷ = pairwise_l2_norm(emb1, emb2)
                #embed1 = emb1
                #embed2 = emb2
                #y_hat = ŷ
                #y_bald = y
                training_loss = Flux.mse(ŷ, y) 
            end
            loss += training_loss 
            #println("loss: ", training_loss)
            #println("y_bald: ", y_bald)
            #println("y_hat: ", y_hat)
            #println("embed1: ", embed1)
            #println("embed2: ", embed2)
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

