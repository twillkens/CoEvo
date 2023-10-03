module Types

export GenotypeSumMetric, GenotypeSizeMetric

using ..Abstract: GenotypeMetric

"""
    GenotypeSum

A metric that represents the sum of a genotype's elements.

# Fields
- `name::String`: Name of the metric, defaulting to "GenotypeSum".
"""
Base.@kwdef struct GenotypeSumMetric <: GenotypeMetric
    name::String = "GenotypeSum"
end

"""
    GenotypeSize

A metric used to indicate the size or length of a genotype.

# Fields
- `name::String`: Name of the metric, defaulting to "GenotypeSize".
"""
Base.@kwdef struct GenotypeSizeMetric <: GenotypeMetric
    name::String = "GenotypeSize"
end

end
