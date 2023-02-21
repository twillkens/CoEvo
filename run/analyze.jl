using Distributed
@everywhere include("../src/Coevolutionary.jl")
@everywhere using .Coevolutionary
@everywhere using Flux
@everywhere using Flux: onecold, onehotbatch, logitcrossentropy
@everywhere using Flux: DataLoader
@everywhere using GraphNeuralNetworks
@everywhere using MLDatasets
@everywhere using MLUtils
@everywhere using LinearAlgebra, Random, Statistics
@everywhere using JLD2
@everywhere using StatsBase
@everywhere using StableRNGs

@everywhere include("fluxclass.jl")
@everywhere include("graphflux.jl")
@everywhere include("fetchpairs.jl")
@everywhere include("fsm.jl")
include("mytrain.jl")


