


function get_embeddings(model::GNN, graphs)
    embeddings = Vector{Vector{Float32}}()
    for graph in ProgressBar(graphs)
        push!(embeddings, model(graph |> gpu) |> vec)
    end
    return embeddings
end

function doit(fsms, fname = "addressa.csv", model = deserialize("model_large_uniform.jls"))
    embs = get_embeddings(model, fsms)
    df = DataFrame(Array(transpose(hcat(embs...))), :auto)
    CSV.write(fname, df)
end


function compare(x, dset, model)
           pred = norm(model(dset[x].g1 |> gpu) - model(dset[x].g2 |> gpu)) |> cpu
           actual = dset[x].dists["raw"]
           s1 = dset[x].g1.num_nodes
           s2 = dset[x].g2.num_nodes
           println("pred: $pred")
           println("actual: $actual")
           println("s1: $s1")
           println("s2: $s2")
       end

function dorun(n, dset; numtrain = (0.1, 0.01), model = nothing, η = 0.001, d1=256, d2=128, d3=64, dout=256)
           if model === nothing
               model = mytrain(dset; numtrain=numtrain, infotime=1, epochs=1, dist="raw", d1=d1, d2=d2, d3=d3, dout=dout, η=η)
           end
           for i in 1:n
               println("Epoch: $i")
               model = mytrain(dset, model; numtrain=numtrain, infotime=1, epochs=1, dist="raw", η=η)
           end
           model
       end

