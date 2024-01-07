module Efficient

export EfficientFunctionGraphPhenotype, EfficientFunctionGraphNode
export EfficientFunctionGraphConnection
export EfficientFunctionGraphPhenotypeCreator
export EfficientFunctionGraphPhenotypeState, get_node_value, get_phenotype_state
export create_phenotype, act!, reset!
export safe_median, get_node_median_value, sort_layer, construct_layers

import ...Phenotypes: create_phenotype, act!, reset!, get_phenotype_state

using Base: @kwdef
using StatsBase: median
using ....Genotypes
using ....Genotypes.FunctionGraphs
using ....Genotypes.FunctionGraphs: GraphFunction
using ....Genotypes.FunctionGraphs: FUNCTION_MAP
using ...Phenotypes: Phenotype, PhenotypeCreator, PhenotypeState
using StaticArrays

include("structs.jl")

include("layers.jl")

include("create.jl")

include("act.jl")

include("prune.jl")

end