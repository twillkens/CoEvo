using ....CoEvo.Ecosystems.Species.Substrates.Vectors: BasicVectorGenotype
using ....CoEvo.Utilities.Metrics: GenotypeSize

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