using ...Phenotypes.Vectors: BasicVectorPhenotype

Base.@kwdef struct NumbersGamePhenotypeCreator <: PhenotypeCreator 
    use_delta::Bool = true
    delta::Float64 = 0.25
end

function round_to_nearest_delta(vector::Vector{Float64}, delta::Float64)
    return [floor(x/delta) * delta for x in vector]
end


function create_phenotype(
    phenotype_creator::NumbersGamePhenotypeCreator, id::Int, genotype::BasicVectorGenotype, 
) 
    if phenotype_creator.use_delta
        values = round_to_nearest_delta(genotype.genes, phenotype_creator.delta)
    else
        values = copy(genotype.genes)
    end
    return BasicVectorPhenotype(id, values)
end