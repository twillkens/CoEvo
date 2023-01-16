"""
Extracts a dictionary of String keys and Genotype values from a Population
"""

function Dict{String, Population}(pops::Set{<:Population})
    Dict{String, Population}([pop.key => pop for pop in pops])
end

include("geno.jl")
include("pareto.jl")