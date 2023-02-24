module CoEvo

using Distributed
using Random
using StableRNGs
using StatsBase
using Combinatorics
using Distributions
using JLD2
using DataStructures

include("abstract/abstract.jl")

const KEY_SPLIT_TOKEN = "-"

include("base/base.jl")
include("domains/domains.jl")

end 