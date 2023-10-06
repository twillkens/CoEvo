module Common

export AllSpeciesMeasurement  

using ....Species.Abstract: AbstractSpecies
using ...Measurements.Abstract: Measurement

Base.@kwdef struct AllSpeciesMeasurement{S <: AbstractSpecies} <: Measurement 
    species::Dict{String, S}
end

end