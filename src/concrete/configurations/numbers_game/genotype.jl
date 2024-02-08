using ...Genotypes.Vectors: BasicVectorGenotype

Base.@kwdef struct NumbersGameVectorGenotypeCreator{T <: Real} <: GenotypeCreator
    length::Int = 5
    init_range::Tuple{T, T} = (0.0, .1)
end

function create_genotypes(
    genotype_creator::NumbersGameVectorGenotypeCreator, n_population::Int, state::State   
)
    genotypes = BasicVectorGenotype{Float64}[]
    for _ in 1:n_population
        genes = zeros(Float64, genotype_creator.length)
        init_start = genotype_creator.init_range[1]
        init_end = genotype_creator.init_range[2]
        for i in 1:genotype_creator.length
            genes[i] = rand(state.rng, init_start:0.01:init_end)
        end
        genotype = BasicVectorGenotype(genes)
        push!(genotypes, genotype)
    end

    return genotypes
end