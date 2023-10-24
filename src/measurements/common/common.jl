module Common

export AllSpeciesMeasurement  

using ...Species: AbstractSpecies
using ..Measurements: Measurement

Base.@kwdef struct AllSpeciesMeasurement{S <: AbstractSpecies} <: Measurement 
    species::Dict{String, S}
end

end