module Genotypes

export GenotypeSize, GenotypeSum

import ..Metrics.Interfaces: measure

using ...Genotypes.Abstract: Genotype
using ..Metrics.Abstract: Metric

Base.@kwdef struct GenotypeSize <: Metric 
    name::String = "GenotypeSize"
    minimize::Bool = false
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