include("run/fsm.jl")

pdispatch(;
    fn = run_4MismatchMix,
    ngen = 50_000,
    trange = 21:40
)