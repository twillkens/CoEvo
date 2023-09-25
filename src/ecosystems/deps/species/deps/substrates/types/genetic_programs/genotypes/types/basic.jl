export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration

using Random: AbstractRNG

using .....CoEvo.Abstract: GeneticProgramGenotype, GeneticProgramGenotypeConfiguration
using .....CoEvo.Utilities.Counters: Counter, next!

Base.@kwdef mutable struct BasicGeneticProgramGenotype <: GeneticProgramGenotype
    root_id::Int = 1
    functions::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
    terminals::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
end

function Base.:(==)(a::BasicGeneticProgramGenotype, b::BasicGeneticProgramGenotype)
    return a.root_id == b.root_id &&
           a.functions == b.functions &&
           a.terminals == b.terminals
end

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

Base.@kwdef struct BasicGeneticProgramGenotypeConfiguration <: GeneticProgramGenotypeConfiguration 
    startval::Union{Symbol, Function, Real} = 0.0
end

function(geno_cfg::BasicGeneticProgramGenotypeConfiguration)(
    ::AbstractRNG, gene_id_counter::Counter
)
    root_id = next!(gene_id_counter)
    BasicGeneticProgramGenotype(
        root_id = root_id,
        terminals = Dict(root_id => ExpressionNodeGene(root_id, nothing, geno_cfg.startval)),
    )
end