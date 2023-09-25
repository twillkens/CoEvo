export SizeGenotypeReporter, SumGenotypeReporter

using ....CoEvo.Abstract: Individual, Genotype
using .Abstract: GenotypeCohortMetricReporter
using ..Genotypes: VectorGenotype


Base.@kwdef struct SizeGenotypeReporter <: GenotypeCohortMetricReporter
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
    genotypes::Vector{<:Genotype}
)
    sizes = [length(geno) for geno in genotypes]
    report = reporter(gen, species_id, generational_type, sizes)
    return report
end

Base.@kwdef struct SumGenotypeReporter <: GenotypeCohortMetricReporter
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
    genotypes::Vector{<:VectorGenotype}
)
    genotype_sum = [sum(geno.vals) for geno in genotypes]
    report = reporter(gen, species_id, cohort, genotype_sum)
    return report
end