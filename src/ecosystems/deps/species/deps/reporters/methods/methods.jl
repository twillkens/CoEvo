using ....CoEvo.Abstract: Evaluation
using ....CoEvo.Utilities.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness
using ....CoEvo.Ecosystems.Species.Substrates.Vectors: BasicVectorGenotype

function(reporter::CohortMetricReporter{<:GenotypeSize})(
    gen::Int,
    species_id::String,
    cohort::String,
    genotypes::Vector{<:BasicVectorGenotype}
)
    sizes = Float64[length(geno) for geno in genotypes]
    report = reporter(gen, species_id, cohort, sizes)
    return report
end

function(reporter::CohortMetricReporter{GenotypeSum})(
    gen::Int,
    species_id::String,
    cohort::String,
    genotypes::Vector{<:BasicVectorGenotype}
)
    genotype_sums = [sum(geno.genes) for geno in genotypes]
    report = reporter(gen, species_id, cohort, genotype_sums)
    return report
end

function(reporter::CohortMetricReporter{EvaluationFitness})(
    gen::Int,
    species_id::String,
    cohort::String,
    evaluations::Vector{<:Evaluation}
)
    fitnesses = [eval.fitness for eval in evaluations]
    report = reporter(gen, species_id, cohort, fitnesses)
    return report
end

