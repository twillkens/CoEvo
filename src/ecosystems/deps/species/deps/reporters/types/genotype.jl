export SizeGenotypeReporter, SumGenotypeReporter

using ....CoEvo.Abstract: Individual
using .Abstract: IndividualReporter
using ..Genotypes: VectorGenotype


Base.@kwdef struct SizeGenotypeReporter <: IndividualReporter
    metric::String = "Genotype Size"
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 2
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end

function(reporter::SizeGenotypeReporter)(
    gen::Int,
    species_id::String,
    generational_type::String,
    genotypes::Vector{<:Individual}
)
    genotypes = map(individual -> individual.geno, genotypes)
    sizes = map(genotype -> Float64(length(genotype)), genotypes)
    report = reporter(gen, species_id, generational_type, sizes)
    return report
end

Base.@kwdef struct SumGenotypeReporter <: IndividualReporter
    metric::String = "Genotype Sum"
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 2
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end

function(reporter::SumGenotypeReporter)(
    gen::Int,
    species_id::String,
    cohort::String,
    indivs::Vector{<:Individual}
)
    genotype_sum = sum(indiv.geno.vals for indiv in indivs)
    report = reporter(gen, species_id, cohort, genotype_sum)
    return report
end