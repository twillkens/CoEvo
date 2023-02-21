using TSne, Statistics, MLDatasets
using Plots

function do_tsne(A, fname::String = "myplot.pdf")
    rescale(A; dims=1) = (A .- mean(A, dims=dims)) ./ max.(std(A, dims=dims), eps())

    alldata, allabels = MNIST.traindata(Float64);
    data = reshape(permutedims(alldata[:, :, 1:2500], (3, 1, 2)),
                2500, size(alldata, 1)*size(alldata, 2));
    # Normalize the data, this should be done if there are large scale differences in the dataset
    X = rescale(data, dims=1);

    Y = tsne(X, 2, 50, 1000, 20.0);

    theplot = scatter(Y[:,1], Y[:,2], marker=(2,2,:auto,stroke(0)), color=Int.(allabels[1:size(Y,1)]))
    Plots.pdf(theplot, fname)
end