include("run/fsm.jl")

println("ARGS[1] = ", ARGS[1])
v = parse(Int, ARGS[1])
sdispatch(;
    fn = runmix,
    ngen = 20_000, 
    trange = v:v,
    domains=[LingPredGame(MatchCoop()), LingPredGame(MatchComp())]
)