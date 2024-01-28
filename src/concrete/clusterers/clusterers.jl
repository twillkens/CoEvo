module Clusterers

export XMeans, GlobalKMeans, NonNegativeMatrixFactorization

include("xmeans/xmeans.jl")
using .XMeans: XMeans

include("global_kmeans/global_kmeans.jl")
using .GlobalKMeans: GlobalKMeans

include("nmf/nmf.jl")
using .NonNegativeMatrixFactorization: NonNegativeMatrixFactorization

end