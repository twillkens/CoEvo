
module Measure

using DataStructures: OrderedDict

using ..Basic: BasicSpeciesReporter 
using ..Abstract: SpeciesReport, SpeciesReporter, Genotype, Evaluation, Individual
using ....Ecosystems.Metrics.Species.Genotype.Types: GenotypeSumMetric, GenotypeSizeMetric
using ....Ecosystems.Metrics.Species.Evaluation.Abstract: EvaluationMetric
using ....Ecosystems.Metrics.Species.Genotype.Abstract: GenotypeMetric
using ....Ecosystems.Metrics.Species.Individual.Abstract: IndividualMetric
using ....Ecosystems.Metrics.Species.Evaluation.Types: EvaluationFitnessMetric
using ....Ecosystems.Metrics.Species.Individual.Types: IndividualIdentityMetric

# Create a report for BasicSpeciesReporter when metric is GenotypeSize.
# Extract the size (length) of each genotype from the given genotypes.
function measure(
    ::BasicSpeciesReporter{GenotypeSizeMetric},
    genotypes::Vector{<:Genotype}
)
    sizes = Float64[length(geno) for geno in genotypes]
    measure_set = BasicStatisticalMeasureSet(sizes)
    return measure_set
end

# Create a report for BasicSpeciesReporter when metric is GenotypeSum.
# Sum up the genes in each genotype from the given genotypes.
function measure(
    ::BasicSpeciesReporter{GenotypeSumMetric},
    genotypes::Vector{<:Genotype}
)
    genotype_sums = [sum(geno.genes) for geno in genotypes]
    measure_set = BasicStatisticalMeasureSet(genotype_sums)
    return measure_set
end

# Create a report for BasicSpeciesReporter when metric is EvaluationFitness.
# Extract the fitness from each evaluation from the given evaluations.
function measure(
    ::BasicSpeciesReporter{EvaluationFitnessMetric},
    evaluations::Vector{<:Evaluation}
)
    fitnesses = [get_fitness(eval) for eval in evaluations]
    measure_set = BasicStatisticalMeasureSet(fitnesses)
    return measure_set
end
function measure(
    reporter::SpeciesReporter{<:IndividualIdentityMetric},
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    individuals = collect(keys(indiv_evals))
    measure_set = measure(reporter, individuals)
    return measure_set
end

function measure(
    reporter::SpeciesReporter{<:EvaluationMetric},
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    evaluations = collect(values(indiv_evals))
    measure_set = measure(reporter, evaluations)
    return measure_set
end

function measure(
    reporter::SpeciesReporter{<:GenotypeMetric},
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    genotypes = [indiv.geno for indiv in keys(indiv_evals)]
    measure_set = measure(reporter, genotypes)
    return measure_set
end

end