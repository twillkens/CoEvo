module SpreadDodo

export SpreadDodoEvaluator, SpreadDodoEvaluation, evaluate
export SpreadDodoEvaluator, SpreadDodoRecord, SpreadDodoEvaluation

import ....Interfaces: evaluate
using Clustering
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ....Abstract
using ....Interfaces
using ...Criteria

include("structs.jl")

include("sillhouette_kmeans.jl")

include("cluster.jl")

include("evaluate.jl")

end