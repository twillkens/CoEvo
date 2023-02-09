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
using FieldProperties

include("abstract/abstract.jl")

const KEY_SPLIT_TOKEN = "-"

include("base/base.jl")
include("domains/domains.jl")

end # end of module