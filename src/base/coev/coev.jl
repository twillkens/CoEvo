module Coev
using ..Common
using ..Reproduction
using JLD2
include("cfg.jl")
include("unfreeze.jl")

export evolve!
function evolve!(
    start::Int, ngen::Int, coev_cfg::CoevConfig, allsp::Dict{Symbol, <:Species},
)
    eco, trial = coev_cfg.eco, coev_cfg.trial
    println("starting: $eco-$trial")
    for gen in start:ngen
        allsp = coev_cfg(gen, allsp)
    end
end
end