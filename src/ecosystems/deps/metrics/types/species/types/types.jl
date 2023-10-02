module Types

using ..Species.Abstract: SpeciesMetric

Base.@kwdef struct FitnessMetric <: SpeciesMetric 
    name::String = "Fitness"
end

end