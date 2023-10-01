module Custom

using ..Basic: BasicSpeciesReporter 
using ....Ecosystems.Species.Abstract: AbstractSpecies
using ....Ecosystems.Species.Evaluators.Types: ScalarFitnessEvaluation
using ...Reporters.Species.Abstract: SpeciesReport, SpeciesReporter
using ....Ecosystems.Metrics.Species.Types: FitnessMetric
using ....Measures: BasicStatisticalMeasureSet


#function measure(
#    ::BasicSpeciesReporter{SpeciesIdentity},
#    species::AbstractSpecies,
#    ::Evaluation
#)
#    measure_set = SpeciesMeasureSet(species)
#    return measure_set
#end
# Create a report for BasicSpeciesReporter when metric is GenotypeSize.
# Extract the size (length) of each genotype from the given genotypes.
#function measure(
#    ::BasicSpeciesReporter{GenotypeSize},
#    species::AbstractSpecies,
#    ::Evaluation
#)
#    genotypes = [indiv.geno for indiv in merge(species.pop, species.children)]
#    sizes = Float64[length(geno) for geno in genotypes]
#    measure_set = BasicStatisticalMeasureSet(sizes)
#    return measure_set
#end


# Create a report for BasicSpeciesReporter when metric is EvaluationFitness.
# Extract the fitness from each evaluation from the given evaluations.
function measure(
    ::BasicSpeciesReporter{FitnessMetric},
    ::AbstractSpecies,
    evaluation::ScalarFitnessEvaluation
)
    fitnesses = collect(values(evaluation.fitnesses))
    measure_set = BasicStatisticalMeasureSet(fitnesses)
    return measure_set
end

end