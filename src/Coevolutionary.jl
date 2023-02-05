module Coevolutionary

using Random
using StableRNGs
using StatsBase
using Combinatorics
using Distributions
using JLD2
using DataStructures
using LRUCache
using AutoHashEquals

include("abstract/abstract.jl")

const KEY_SPLIT_TOKEN = "-"
# const fitness_lru = LRU{Individual, Float64}(maxsize=1000)
# const testscores_lru = LRU{Individual, SortedDict{String, Float64}}(maxsize=1000)

include("base/base.jl")
include("domains/domains.jl")

end # end of module