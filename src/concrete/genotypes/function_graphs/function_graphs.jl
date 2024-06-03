"""
    FunctionGraphs

A module that provides functionality for creating, manipulating, and analyzing
function graphs,

# Contents:
- Genotype representation of function graphs (`genotype.jl`).
- Equality testing for function graph genotypes (`equals.jl`).
- Minimization algorithms for function graph genotypes (`minimize.jl`).
- Display utilities for function graph genotypes (`show.jl`).
- Mapping between function symbols and their executable implementations (`function_map.jl`).
"""
module FunctionGraphs

export evaluate_function
export FunctionGraphGenotype, FunctionGraphGenotypeCreator
export Edge, Node
export create_genotypes
export FUNCTION_MAP, GraphFunction, evaluate_function, InputGraphFunction, BiasGraphFunction
export OutputGraphFunction, IdentityGraphFunction, AddGraphFunction, SubtractGraphFunction
export MultiplyGraphFunction, GraphDivide, MaximumGraphFunction, MinimumGraphFunction
export SineGraphFunction, CosineGraphFunction, SigmoidGraphFunction, TanhGraphFunction
export ReluGraphFunction, AndGraphFunction, OrGraphFunction, NandGraphFunction, XorGraphFunction
export IfLessThenElseGraphFunction, ModuloGraphFunction, NaturalLogGraphFunction, ExpGraphFunction
export get_size, minimize
export remove_node_and_redirect, substitute_node_with_bias_connection, get_prunable_genes
export validate_genotype, has_cycle_nonrecurrent

import ....Interfaces: create_genotypes, get_size, minimize

using Base: @kwdef
using ....Abstract: Genotype, GenotypeCreator, AbstractRNG, Counter
using ....Interfaces: step!

include("function_map.jl")

include("genotype.jl")

include("getters.jl")
#include("equals.jl")

include("minimize.jl")

include("show.jl")

include("sort.jl")

include("validate.jl")

include("manipulate/manipulate.jl")

include("archive.jl")

include("modes_prune.jl")

end