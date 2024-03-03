module Tin

export TinEvaluator, TinEvaluation, evaluate
export TinEvaluator, TinRecord, TinEvaluation

import ....Interfaces: evaluate
using Clustering
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ....Abstract
using ....Interfaces
using ...Criteria

include("structs.jl")

include("filter.jl")

include("sillhouette_kmeans.jl")

include("cluster.jl")

include("evaluate.jl")

end