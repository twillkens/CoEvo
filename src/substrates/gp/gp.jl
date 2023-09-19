module GP
using Random
using StatsBase
using ..Common
using JLD2
include("util.jl")
include("geno.jl")
include("mutator.jl")
include("pheno.jl")
include("graphpheno.jl")
include("archiver.jl")
end