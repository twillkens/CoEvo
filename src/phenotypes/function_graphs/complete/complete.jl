module Complete

export CompleteFunctionGraphPhenotype, Node
export Edge
export CompleteFunctionGraphPhenotypeCreator
export CompleteFunctionGraphPhenotypeState, get_node_value, get_phenotype_state
export create_phenotype, act!, reset!
export safe_median, get_node_median_value

import ...Phenotypes: create_phenotype, act!, reset!, get_phenotype_state

using Base: @kwdef
using StatsBase: median
using ....Genotypes
using ....Genotypes.SimpleFunctionGraphs
using ....Genotypes.SimpleFunctionGraphs: GraphFunction
using ....Genotypes.SimpleFunctionGraphs: FUNCTION_MAP
using ...Phenotypes: Phenotype, PhenotypeCreator, PhenotypeState
using StaticArrays

include("structs.jl")

include("create.jl")

include("act.jl")

include("prune.jl")

end