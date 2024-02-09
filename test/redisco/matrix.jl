using CoEvo
using Serialization
using CoEvo.Concrete.Clusterers.GlobalKMeans
using Random


m = deserialize("test/redisco/matrix.jls")

rng = Random.GLOBAL_RNG
r = get_fast_global_clustering_result(rng, m.data, max_clusters = 5)
println("done")