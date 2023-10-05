module Genotypes

export GenotypeSize, GenotypeSum

using ...Metrics.Abstract: Metric
using ....Species.Genotypes.Abstract: Genotype


Base.@kwdef struct GenotypeSize <: Metric 
    name::String = "GenotypeSize"
end

function measure(::GenotypeSize, genotype::Genotype)
    size = length(genotype)
    return size
end

Base.@kwdef struct GenotypeSum <: Metric 
    name::String = "GenotypeSum"
end

function measure(::GenotypeSum, genotype::Genotype)
    return sum(genotype)
end

end