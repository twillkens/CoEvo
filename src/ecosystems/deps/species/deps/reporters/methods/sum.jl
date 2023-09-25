using ....CoEvo.Ecosystems.Species.Genotypes: VectorGenotype
using ....CoEvo.Utilities.Metrics: GenotypeSum

function(reporter::CohortMetricReporter{GenotypeSum})(
    gen::Int,
    species_id::String,
    cohort::String,
    genotypes::Vector{<:VectorGenotype}
)
    genotype_sums = [sum(geno.vals) for geno in genotypes]
    report = reporter(gen, species_id, cohort, genotype_sums)
    return report
end