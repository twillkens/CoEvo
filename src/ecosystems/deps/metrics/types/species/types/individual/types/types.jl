module Types

export IndividualIdentityMetric

using .....Ecosystems.Metrics.Species.Genotype.Abstract: GenotypeMetric

Base.@kwdef struct IndividualIdentityMetric <: GenotypeMetric
    name::String = "IndividualIdentity"
end

end
