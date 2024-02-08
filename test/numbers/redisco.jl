
using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Concrete.Matrices.Outcome
using CoEvo.Concrete.Clusterers.GlobalKMeans
using CoEvo.Concrete.Evaluators.Redisco
using Random

matrix = Float64[
    0 0 0 0 0 ;
    0 0 0 0 0 ;
    1 1 0 0 0 ;
    1 1 0 0 0 ;
    1 1 1 0 0 ;
    1 1 1 0 0 ;
    0 0 1 1 1 ;
    0 0 1 1 1 ;
    0 0 0 1 1 ;
    0 0 0 1 1 ;
]

matrix = OutcomeMatrix(matrix)

Base.@kwdef struct DummyState <: State
    rng::Random.MersenneTwister = Random.MersenneTwister(1234)
end

println("hi")

evaluation = evaluate(
    RediscoEvaluator(3),
    [5, 9],
    matrix,
    DummyState()
)
println("wow")
println(evaluation.hillclimber_ids)
