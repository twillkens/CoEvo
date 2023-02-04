module Coevolutionary

using Random
using StableRNGs
using StatsBase
using Combinatorics
using Distributions
using JLD2
using DataStructures
using LRUCache

const KEY_SPLIT_TOKEN = "-"

include("base/base.jl")
#include("genotypes/genotypes.jl")
include("domains/domains.jl")

end # end of module