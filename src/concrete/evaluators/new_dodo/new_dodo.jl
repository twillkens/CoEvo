module NewDodo

export NewDodoEvaluator, NewDodoEvaluation, evaluate
export NewDodoEvaluator, NewDodoRecord, NewDodoEvaluation

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