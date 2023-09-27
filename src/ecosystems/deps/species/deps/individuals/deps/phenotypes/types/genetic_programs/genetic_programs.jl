
module GeneticPrograms

export BasicGeneticProgramPhenotype

using ...Individuals.Genotypes.GeneticPrograms: BasicGeneticProgramGenotype
using ..Abstract: PhenotypeCreator, Phenotype


include("deps/linear_node.jl")

mutable struct BasicGeneticProgramPhenotype <: Phenotype
    tape::Vector{Real}
    head::Int
    linear_nodes::Vector{LinearNode}
end

function BasicGeneticProgramPhenotype(
    genotype::BasicGeneticProgramGenotype, tape::Vector{<:Real} = [0.0]
)
    linear_nodes = linearize(genotype)
    head = length(data)
    BasicGeneticProgramPhenotype(tape, head, linear_nodes)
end

function create_phenotype(::PhenotypeCreator, geno::BasicGeneticProgramGenotype)
    BasicGeneticProgramPhenotype(geno)
end

end