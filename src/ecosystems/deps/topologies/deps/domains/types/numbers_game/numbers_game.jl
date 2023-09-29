module NumbersGame

export Metrics, Domain

include("metrics.jl")
using .Metrics: Metrics

include("creator.jl")
using .Creator: Creator

end
