using ...Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ...Evaluators.NSGAII: NSGAIIEvaluator

const EVALUATORS = Dict(
    "scalar" => ScalarFitnessEvaluator(),
    "disco" => NSGAIIEvaluator(
        maximize = true,
        max_clusters = 3,
        clusterer = "global_kmeans",
        distance_method = "euclidean"
    ),
)