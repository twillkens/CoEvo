module Modi

using Random: AbstractRNG
using ......Ecosystems.Utilities.Counters: Counter, next!
using ...GeneticPrograms.Abstract: GeneticProgramGenotype, ExpressionNodeGene
using ...GeneticPrograms.Abstract: GeneticProgramGenotypeCreator

import ....Genotypes.Interfaces: create_genotypes   

mutable struct ModiExpressionNodeGene <: ExpressionNodeGene
    id::Int
    parent_id::Union{Int, Nothing}
    val::Union{Symbol, Function, Real}
    child_ids::Vector{Int}
    modi_id::Int
end

function ModiExpressionNodeGene(
    id::Int, parent::Union{Int, Nothing}, val::Union{Symbol, Function, Real}
)
    ModiExpressionNodeGene(id, parent, val, Int[], 0)
end

Base.@kwdef struct ModiGeneticProgramGenotypeCreator <: GeneticProgramGenotypeCreator
    default_terminal_value::Union{Symbol, Function, Real} = 0.0
    n_modi::Int = 1
end

Base.@kwdef struct ModiGeneticProgramGenotype <: GeneticProgramGenotype
    root_ids = Vector{Int}()
    functions::Dict{Int, ModiExpressionNodeGene} = Dict{Int, ModiExpressionNodeGene}()
    terminals::Dict{Int, ModiExpressionNodeGene} = Dict{Int, ModiExpressionNodeGene}()
end

function create_genotype(
    geno_creator::ModiGeneticProgramGenotypeCreator,
    gene_id_counter::Counter
)
    root_id = next!(gene_id_counter)
    genotype = ModiGeneticProgramGenotype(
        root_id = root_id,
        terminals = Dict(
            root_id => ModiExpressionNodeGene(
                root_id, nothing, geno_creator.default_terminal_value
            )
        )
    )
    return genotype
end

function create_genotypes(
    geno_creator::ModiGeneticProgramGenotypeCreator,
    ::AbstractRNG,
    gene_id_counter::Counter,
    n_pop::Int
)
    genotypes = [create_genotype(geno_creator, gene_id_counter) for _ in 1:n_pop]
    return genotypes
end
end
