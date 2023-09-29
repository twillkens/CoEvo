
module Measure

using ..Abstract: SpeciesReport, SpeciesReporter, Genotype, Evaluation
using ..Metrics: GenotypeSum, GenotypeSize, EvaluationFitness


# Create a report for BasicSpeciesReporter when metric is GenotypeSize.
# Extract the size (length) of each genotype from the given genotypes.
function measure(
    ::BasicSpeciesReporter{GenotypeSize},
    genotypes::Vector{<:Genotype}
)
    sizes = Float64[length(geno) for geno in genotypes]
    measure_set = BasicStatisticalMeasureSet(sizes)
    return measure_set
end

# Create a report for BasicSpeciesReporter when metric is GenotypeSum.
# Sum up the genes in each genotype from the given genotypes.
function measure(
    ::BasicSpeciesReporter{GenotypeSum},
    genotypes::Vector{<:Genotype}
)
    genotype_sums = [sum(geno.genes) for geno in genotypes]
    measure_set = BasicStatisticalMeasureSet(genotype_sums)
    return measure_set
end

# Create a report for BasicSpeciesReporter when metric is EvaluationFitness.
# Extract the fitness from each evaluation from the given evaluations.
function measure(
    ::BasicSpeciesReporter{EvaluationFitness},
    evaluations::Vector{<:Evaluation}
)
    fitnesses = [get_fitness(eval) for eval in evaluations]
    measure_set = BasicStatisticalMeasureSet(fitnesses)
    return measure_set
end

end