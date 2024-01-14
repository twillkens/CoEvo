module MatchMakers

export AllVersusAll, OneVersusAll, RandomSample

include("all_vs_all/all_vs_all.jl")
using .AllVersusAll: AllVersusAll

include("one_vs_all/one_vs_all.jl")
using .OneVersusAll: OneVersusAll

include("random_sample/random_sample.jl")
using .RandomSample: RandomSample

end
