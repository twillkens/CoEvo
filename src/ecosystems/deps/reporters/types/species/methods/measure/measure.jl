
module Measure

using DataStructures: OrderedDict

using ..Basic: BasicSpeciesReporter 
using ...Reporters.Species.Abstract: SpeciesReport, SpeciesReporter
using ....Ecosystems.Metrics.Species: Species as SpeciesMetrics
using .SpeciesMetrics.Genotype.Types: GenotypeSumMetric, GenotypeSizeMetric
using .SpeciesMetrics.Evaluation.Abstract: EvaluationMetric
using .SpeciesMetrics.Genotype.Abstract: GenotypeMetric
using .SpeciesMetrics.Individual.Abstract: IndividualMetric
using .SpeciesMetrics.Evaluation.Types: EvaluationFitnessMetric
using .SpeciesMetrics.Individual.Types: IndividualIdentityMetric

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
)
    genotypes = [indiv.geno for indiv in keys(indiv_evals)]
    measure_set = measure(reporter, genotypes)
    return measure_set
end

end