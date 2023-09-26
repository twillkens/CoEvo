export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration

using Random: AbstractRNG

using .....CoEvo.Abstract: GeneticProgramGenotype, GeneticProgramGenotypeConfiguration
using .....CoEvo.Utilities.Counters: Counter, next!


"""
    BasicGeneticProgramGenotype <: GeneticProgramGenotype

A simple genetic program genotype representation.

# Fields:
- `root_id::Int`: The ID of the root node.
- `functions::Dict{Int, ExpressionNodeGene}`: A dictionary of function nodes keyed by their unique identifiers.
- `terminals::Dict{Int, ExpressionNodeGene}`: A dictionary of terminal nodes keyed by their unique identifiers.
"""
Base.@kwdef mutable struct BasicGeneticProgramGenotype <: GeneticProgramGenotype
    root_id::Int = 1
    functions::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
    terminals::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
end

"""
    ==(a::BasicGeneticProgramGenotype, b::BasicGeneticProgramGenotype) -> Bool

Compare two `BasicGeneticProgramGenotype` instances for equality.

# Arguments
- `a::BasicGeneticProgramGenotype`: First genotype to compare.
- `b::BasicGeneticProgramGenotype`: Second genotype to compare.

# Returns
- `Bool`: `true` if the genotypes are equal, otherwise `false`.
"""
function Base.:(==)(a::BasicGeneticProgramGenotype, b::BasicGeneticProgramGenotype)
    return a.root_id == b.root_id &&
           a.functions == b.functions &&
           a.terminals == b.terminals
end

"""
    show(io::IO, geno::BasicGeneticProgramGenotype)

Display a textual representation of the `BasicGeneticProgramGenotype` to the provided IO stream.

# Arguments
- `io::IO`: The IO stream to write to.
- `geno::BasicGeneticProgramGenotype`: The genotype instance to display.
"""
function Base.show(io::IO, geno::BasicGeneticProgramGenotype)
    print(io, "BasicGeneticProgramGenotype(\n")
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

"""
    BasicGeneticProgramGenotypeConfiguration <: GeneticProgramGenotypeConfiguration 

Configuration for creating a `BasicGeneticProgramGenotype`.

# Fields:
- `startval::Union{Symbol, Function, Real}`: Initial value to be used for the terminal node. Default is `0.0`.
"""
Base.@kwdef struct BasicGeneticProgramGenotypeConfiguration <: GeneticProgramGenotypeConfiguration 
    startval::Union{Symbol, Function, Real} = 0.0
end

"""
    (geno_cfg::BasicGeneticProgramGenotypeConfiguration)(rng::AbstractRNG, gene_id_counter::Counter) -> BasicGeneticProgramGenotype

Construct a `BasicGeneticProgramGenotype` using the provided configuration.

# Arguments
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.

# Returns
- `BasicGeneticProgramGenotype`: A new genotype instance.
"""
function(geno_cfg::BasicGeneticProgramGenotypeConfiguration)(
    ::AbstractRNG, gene_id_counter::Counter
)
    root_id = next!(gene_id_counter)
    BasicGeneticProgramGenotype(
        root_id = root_id,
        terminals = Dict(root_id => ExpressionNodeGene(root_id, nothing, geno_cfg.startval)),
    )
end
