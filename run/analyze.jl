using Distributed
#addprocs(5, exeflags="--project=.")
using CoEvo
using Flux
using Flux: onecold, onehotbatch, logitcrossentropy
using Flux: DataLoader
using GraphNeuralNetworks
using MLDatasets
using MLUtils
using LinearAlgebra, Random, Statistics
using MultivariateStats
using Plots
using RDatasets
using Zygote
using CUDA
using JLD2
using Serialization

include("spec.jl")
include("fsmgraph.jl")
include("fetchpairs.jl")
include("fsm.jl")
include("mytrain.jl")


