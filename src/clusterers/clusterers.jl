module Clusterers

export XMeans, GlobalKMeans

include("xmeans/xmeans.jl")
using .XMeans: XMeans

include("global_kmeans/global_kmeans.jl")
using .GlobalKMeans: GlobalKMeans

end