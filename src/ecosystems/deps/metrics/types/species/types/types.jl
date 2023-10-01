module Types

using ..Abstract: SpeciesMetric

Base.@kwdef struct FitnessMetric <: SpeciesMetric 
    name::String = "Fitness"
end

end