using ....CoEvo.Abstract: Evaluation
using ....CoEvo.Utilities.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness
using ....CoEvo.Ecosystems.Species.Substrates.Vectors: BasicVectorGenotype

# Create a report for CohortMetricReporter when metric is GenotypeSize.
# Extract the size (length) of each genotype from the given genotypes.
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

# Create a report for CohortMetricReporter when metric is GenotypeSum.
# Sum up the genes in each genotype from the given genotypes.
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

# Create a report for CohortMetricReporter when metric is EvaluationFitness.
# Extract the fitness from each evaluation from the given evaluations.
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

