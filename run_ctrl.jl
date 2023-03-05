include("run/fsm.jl")

pdispatch(;
    fn = runmix,
    ngen = 50_000,
    domain = [LingPredGame(MismatchCoop()), LingPredGame(MatchComp())]
)