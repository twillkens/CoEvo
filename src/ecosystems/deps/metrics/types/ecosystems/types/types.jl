module Types

export RuntimeMetric

using ..Abstract: EcosystemMetric

Base.@kwdef struct RuntimeMetric <: EcosystemMetric
    name::String = "runtime"
end

end