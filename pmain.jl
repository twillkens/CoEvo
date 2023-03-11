include("run/fsm.jl")

pdispatch(;
    fn = runctrl,
    ngen = 50_000,
    trange = 21:40
)