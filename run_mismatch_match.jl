include("run/fsm.jl")

pdispatch(; ngen = 50_000, domain = [LingPredGame(MismatchCoop()), LingPredGame(MatchComp())])