


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