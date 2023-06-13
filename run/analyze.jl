using Distributed
#addprocs(5, exeflags="--project=.")
using CoEvo
using Flux
using Flux: onecold, onehotbatch, logitcrossentropy, DataLoader
using GraphNeuralNetworks
using MLDatasets
using MLUtils
using LinearAlgebra, Random, Statistics
using MultivariateStats
using Plots
using RDatasets
using Zygote
import CUDA
using JLD2
using Serialization
include("pb.jl")
#using ProgressBars

#using StatsBase

# include("spec.jl")
# include("fsmgraph.jl")
# include("fetchpairs.jl")
# include("fsm.jl")
include("graphs.jl")
include("parsegraph.jl")
include("mytrain.jl")
include("prep_pacmap.jl")


