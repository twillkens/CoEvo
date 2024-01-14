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

import ....Interfaces: create_genotypes, get_size, minimize, load_genotype

using Base: @kwdef
using ....Abstract: Genotype, GenotypeCreator, AbstractRNG, Counter
using ....Interfaces: count!

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

end