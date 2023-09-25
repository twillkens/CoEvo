export PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration

mutable struct PlayerPianoPhenotype <: Phenotype
    ikey::IndivKey
    data::Vector{Real}
    head::Int
    linear_nodes::Vector{LinearNode}
    geno::BasicGeneticProgramGenotype
end

function PlayerPianoPhenotype(ikey::IndivKey, genotype::BasicGeneticProgramGenotype, data::Vector{<:Real} = [0.0, π])
    linear_nodes = linearize(genotype)
    head = length(data)
    PlayerPianoPhenotype(ikey, data, head, linear_nodes, genotype)
end

struct PlayerPianoPhenotypeConfiguration <: PhenotypeConfiguration end

function(cfg::PlayerPianoPhenotypeConfiguration)(
    ikey::IndivKey, geno::BasicGeneticProgramGenotype
)
    PlayerPianoPhenotype(ikey, geno)
end