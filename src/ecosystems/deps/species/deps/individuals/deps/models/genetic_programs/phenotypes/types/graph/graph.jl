export PlayerPianoPhenotype, PlayerPianoPhenotypeCreator

using .......CoEvo.Abstract: Phenotype, PhenotypeCreator

include("deps/linear_node.jl")

mutable struct GraphGeneticProgramPhenotype <: Phenotype
    tape::Vector{Real}
    head::Int
    linear_nodes::Vector{LinearNode}
end

function GraphGeneticProgramPhenotype(
    genotype::BasicGeneticProgramGenotype, tape::Vector{<:Real} = [0.0]
)
    linear_nodes = linearize(genotype)
    head = length(data)
    GraphGeneticProgramPhenotype(tape, head, linear_nodes)
end

function(creator::PhenotypeCreator)(geno::BasicGeneticProgramGenotype)
    GraphGeneticProgramPhenotype(geno)
end