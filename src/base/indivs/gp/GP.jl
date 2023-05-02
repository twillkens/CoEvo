#module GP
using Random: AbstractRNG, default_rng, randperm, shuffle, randn!
using Distributions: Uniform
using StableRNGs
#using CambrianCoev
import Base: show, copy, minimum, summary, getproperty, rand, getindex, length,
             copyto!, setindex!, replace
include("util.jl")
include("protected.jl")
include("expressions.jl")
include("gp.jl")
#include("mut.jl")
#include("recomb.jl")
#include("individual.jl")
#include("agent.jl")
#include("population.jl")
#include("simulate.jl")
#end