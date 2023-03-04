include("run/fsm.jl")
fn = ARGS
fn = getfield(Main, Symbol(fn))
pdispatch(fn = fn)