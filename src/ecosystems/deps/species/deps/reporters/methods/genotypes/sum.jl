using ....CoEvo.Ecosystems.Species.Substrates.Vectors: BasicVectorGenotype
using ....CoEvo.Utilities.Metrics: GenotypeSum

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