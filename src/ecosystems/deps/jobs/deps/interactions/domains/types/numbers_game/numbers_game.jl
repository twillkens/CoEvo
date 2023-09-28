module NumbersGame

export NumbersGameDomain, NumbersGameDomainCreator, create_domain, next!, refresh!, is_active
export get_outcome_set, act, refresh!

include("metrics.jl")
include("domain.jl")
include("outcome_sets.jl")




end
