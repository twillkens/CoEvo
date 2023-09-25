
Base.@kwdef mutable struct BasicGeneticProgramGenotype <: Genotype
    root_gid::Int = 1
    funcs::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
    terms::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
end

function Base.:(==)(a::BasicGeneticProgramGenotype, b::BasicGeneticProgramGenotype)
    return a.root_gid == b.root_gid &&
           a.funcs == b.funcs &&
           a.terms == b.terms
end

function Base.show(io::IO, geno::BasicGeneticProgramGenotype)
    print(io, "BasicGeneticProgramGenotype(\n")
    print(io, "    root_gid = $(geno.root_gid),\n")
    print(io, "    funcs = Dict(\n")
    for (gid, node) in geno.funcs
        print(io, "        $node,\n")
    end
    print(io, "    ),\n")
    print(io, "    terms = Dict(\n")
    for (gid, node) in geno.terms
        print(io, "        $node,\n")
    end
    print(io, "    ),\n")
    print(io, ")")
end

Base.@kwdef struct BasicGeneticProgramGenotypeConfiguration <: GenotypeConfiguration 
    startval::Union{Symbol, Function, Real} = 0.0
end

function(geno_cfg::BasicGeneticProgramGenotypeConfiguration)(
    ::AbstractRNG, gene_id_counter::Counter
)
    root_gid = next!(gene_id_counter)
    BasicGeneticProgramGenotype(
        root_gid = root_gid,
        terms = Dict(root_gid => ExpressionNodeGene(root_gid, nothing, geno_cfg.startval)),
    )
end