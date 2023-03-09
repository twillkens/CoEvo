module CoEvo

using Distributed
using Random
using StableRNGs
using StatsBase
using Combinatorics
using Distributions
using JLD2
using DataStructures
using Pidfile

include("abstract/abstract.jl")

const KEY_SPLIT_TOKEN = "-"
const PFILTER_T = 25

include("base/base.jl")
include("domains/domains.jl")

end 