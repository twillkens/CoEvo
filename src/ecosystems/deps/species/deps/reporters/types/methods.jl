using ...Species.Individuals.Abstract: Individual, Genotype
using ...Species.Evaluators.Abstract: Evaluation
using .Abstract: SpeciesReport, SpeciesReporter
using .Metrics: GenotypeSum, GenotypeSize, EvaluationFitness


# Create a report for BasicSpeciesReporter when metric is GenotypeSize.
# Extract the size (length) of each genotype from the given genotypes.
function create_report(
    reporter::BasicSpeciesReporter{GenotypeSize},
    gen::Int,
    species_id::String,
    cohort::String,
    genotypes::Vector{<:Genotype}
)
    sizes = Float64[length(geno) for geno in genotypes]
    report = reporter(gen, species_id, cohort, sizes)
    return report
end

# Create a report for BasicSpeciesReporter when metric is GenotypeSum.
# Sum up the genes in each genotype from the given genotypes.
function create_report(
    reporter::BasicSpeciesReporter{GenotypeSum},
    gen::Int,
    species_id::String,
    cohort::String,
    genotypes::Vector{<:Genotype}
)
    genotype_sums = [sum(geno.genes) for geno in genotypes]
    report = reporter(gen, species_id, cohort, genotype_sums)
    return report
end

# Create a report for BasicSpeciesReporter when metric is EvaluationFitness.
# Extract the fitness from each evaluation from the given evaluations.
function create_report(
    reporter::BasicSpeciesReporter{EvaluationFitness},
    gen::Int,
    species_id::String,
    cohort::String,
    evaluations::Vector{<:Evaluation}
)
    fitnesses = [fitness(eval) for eval in evaluations]
    report = reporter(gen, species_id, cohort, fitnesses)
    return report
end

