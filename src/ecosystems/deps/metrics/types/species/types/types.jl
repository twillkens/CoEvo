module Types

export GenotypeSize

using ..Species.Abstract: SpeciesMetric

Base.@kwdef struct GenotypeSize <: SpeciesMetric 
    name::String = "GenotypeSize"
end


end