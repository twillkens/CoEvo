module DodoTest

export DodoTestEvaluator, DodoTestEvaluation, evaluate
export child_dominates_parent

import ....Interfaces: evaluate
using Clustering
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ....Abstract
using ....Interfaces
using ...Criteria

include("structs.jl")

include("matrix.jl")

include("dominance.jl")

include("promotions.jl")

include("sillhouette_kmeans.jl")

include("cluster.jl")

include("evaluate.jl")

end