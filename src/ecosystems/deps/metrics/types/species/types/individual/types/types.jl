module Types

export IndividualIdentityMetric

using ..Abstract: GenotypeMetric

Base.@kwdef struct IndividualIdentityMetric <: GenotypeMetric
    name::String = "IndividualIdentity"
end

end
