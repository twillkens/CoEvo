module Types

export GenotypeSize, GenotypeSum

using ..Species.Abstract: SpeciesMetric

Base.@kwdef struct GenotypeSize <: SpeciesMetric 
    name::String = "GenotypeSize"
end

Base.@kwdef struct GenotypeSum <: SpeciesMetric 
    name::String = "GenotypeSum"
end


end