export ExpressionNode, GeneticProgramGenotype, GeneticProgramGenotypeCreator

mutable struct ExpressionNode
    id::Int
    parent_id::Union{Int, Nothing}
    val::Union{Symbol, Function, Real}
    child_ids::Vector{Int}
end

function ExpressionNode(
    id::Int, parent::Union{Int, Nothing}, val::Union{Symbol, Function, Real}
)
    ExpressionNode(id, parent, val, Int[])
end

function Base.:(==)(a::ExpressionNode, b::ExpressionNode)
    return a.id == b.id &&
           a.parent_id == b.parent_id &&
           a.val == b.val &&
           a.child_ids == b.child_ids
end

function Base.show(io::IO, enode::ExpressionNode)
    if length(enode.child_ids) == 0
        children = ""
    else
        children = join([child_id for child_id in enode.child_ids], ", ")
        children = "($children)"
    end
    print(io, "$(enode.parent_id) <= $(enode.id) => $(enode.val)$children")
end

Base.@kwdef mutable struct GeneticProgramGenotype <: GeneticProgramGenotype
    root_id::Int = 1
    functions::Dict{Int, ExpressionNode} = Dict{Int, ExpressionNode}()
    terminals::Dict{Int, ExpressionNode} = Dict{Int, ExpressionNode}()
end

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

Base.@kwdef struct GeneticProgramGenotypeCreator <: GeneticProgramGenotypeCreator 
    default_terminal_value::Union{Symbol, Function, Real} = 0.0
end

function create_genotype(
    geno_creator::GeneticProgramGenotypeCreator,
    gene_id_counter::Counter
)
    root_id = count!(gene_id_counter)
    genotype = GeneticProgramGenotype(
        root_id = root_id,
        terminals = Dict(
            root_id => ExpressionNode(
                root_id, nothing, geno_creator.default_terminal_value
            )
        )
    )
    return genotype
end

function create_genotypes(
    geno_creator::GeneticProgramGenotypeCreator,
    ::AbstractRNG,
    gene_id_counter::Counter,
    n_pop::Int
)
    genotypes = [create_genotype(geno_creator, gene_id_counter) for _ in 1:n_pop]
    return genotypes
end