export PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration

using ......CoEvo.Abstract: Phenotype, PhenotypeConfiguration

include("deps/linear_node.jl")

mutable struct PlayerPianoPhenotype <: Phenotype
    tape::Vector{Real}
    head::Int
    linear_nodes::Vector{LinearNode}
    geno::BasicGeneticProgramGenotype
end

function PlayerPianoPhenotype(
    genotype::BasicGeneticProgramGenotype, tape::Vector{<:Real} = [0.0]
)
    linear_nodes = linearize(genotype)
    head = length(data)
    PlayerPianoPhenotype(tape, head, linear_nodes, genotype)
end

struct PlayerPianoPhenotypeConfiguration <: PhenotypeConfiguration end

function(cfg::PlayerPianoPhenotypeConfiguration)(geno::BasicGeneticProgramGenotype)
    PlayerPianoPhenotype(geno)
end