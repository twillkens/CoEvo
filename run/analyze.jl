using Distributed
@everywhere using CoEvo
@everywhere using Flux
@everywhere using Flux: onecold, onehotbatch, logitcrossentropy
@everywhere using Flux: DataLoader
@everywhere using GraphNeuralNetworks
@everywhere using MLDatasets
@everywhere using MLUtils
@everywhere using LinearAlgebra, Random, Statistics
using MultivariateStats
using Plots
using RDatasets
using Zygote
using CUDA
using JLD2

@everywhere include("spec.jl")
@everywhere include("fsmgraph.jl")
@everywhere include("fetchpairs.jl")
@everywhere include("fsm.jl")
include("mytrain.jl")


