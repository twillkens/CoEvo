module NumbersGame

export Metrics, Domain

include("metrics.jl")
using .Metrics: Metrics

include("domain.jl")
using .Domain: Domain

end
