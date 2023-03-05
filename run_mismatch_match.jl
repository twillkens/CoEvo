include("run/fsm.jl")

pdispatch(; ngen = 50_000, domains = [LingPredGame(MismatchCoop()), LingPredGame(MatchComp())])