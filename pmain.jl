include("run/fsm.jl")

pdispatch(;
    fn = run_3comp,
    ngen = 50_000,
    trange = 1:40
)