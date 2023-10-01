module Genotypes

export GeneticProgramGenotype

using ..Genes: ExpressionNodeGene
using ....Genotypes.Abstract: Genotype

"""
    GeneticProgramGenotype <: GeneticProgramGenotype

A simple genetic program genotype representation.

# Fields:
- `root_id::Int`: The ID of the root node.
- `functions::Dict{Int, ExpressionNodeGene}`: A dictionary of function nodes keyed by their unique identifiers.
- `terminals::Dict{Int, ExpressionNodeGene}`: A dictionary of terminal nodes keyed by their unique identifiers.
"""
Base.@kwdef mutable struct GeneticProgramGenotype <: Genotype
    root_id::Int = 1
    functions::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
    terminals::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
end

"""
    ==(a::GeneticProgramGenotype, b::GeneticProgramGenotype) -> Bool

Compare two `GeneticProgramGenotype` instances for equality.

# Arguments
- `a::GeneticProgramGenotype`: First genotype to compare.
- `b::GeneticProgramGenotype`: Second genotype to compare.

# Returns
- `Bool`: `true` if the genotypes are equal, otherwise `false`.
"""
function Base.:(==)(a::GeneticProgramGenotype, b::GeneticProgramGenotype)
    return a.root_id == b.root_id &&
           a.functions == b.functions &&
           a.terminals == b.terminals
end

"""
    show(io::IO, geno::GeneticProgramGenotype)

Display a textual representation of the `GeneticProgramGenotype` to the provided IO stream.

# Arguments
- `io::IO`: The IO stream to write to.
- `geno::GeneticProgramGenotype`: The genotype instance to display.
"""
function Base.show(io::IO, geno::GeneticProgramGenotype)
    print(io, "GeneticProgramGenotype(\n")
    print(io, "    root_id = $(geno.root_id),\n")
    print(io, "    functions = Dict(\n")
    for (id, node) in geno.functions
        print(io, "        $node,\n")
    end
    print(io, "    ),\n")
    print(io, "    terminals = Dict(\n")
    for (id, node) in geno.terminals
        print(io, "        $node,\n")
    end
    print(io, "    ),\n")
    print(io, ")")
end

end