using Test
using Random
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary
using ProgressBars
using Plots
using JLD2
using StatsBase

function doit()
    geno = FSMGeno(
        IndivKey(:A, 1),
        "0",
        Set{String}(),
        Set{String}(["0"]),
        Dict(("0", true) => "0",
        ("0", false) => "0"))

    m = LingPredMutator(rng = StableRNG(42), sc = SpawnCounter())

    indiv = FSMIndiv(geno.ikey, geno)
    for i in 1:100_000
        indiv = m(indiv)
    end

    println(length(indiv.ones))
    println(length(indiv.zeros))
end