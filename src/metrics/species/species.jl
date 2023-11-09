module Species

using ...Species: AbstractSpecies
using ..Metrics: Metric, Measurement, measure

abstract type SpeciesMetric <: Metric end

struct SaveAllSpeciesMetric <: SpeciesMetric end

struct SaveAllSpeciesMeasurement{S <: AbstractSpecies} <: Measurement
    all_species::Vector{S}
end

function measure(::SaveAllSpeciesMetric, all_species::Vector{<:AbstractSpecies})
    measurement = SaveAllSpeciesMeasurement(all_species)
    return measurement
end

function measure(metric::SpeciesMetric, species::Vector{<:AbstractSpecies})
    measurements = [measure(metric, species) for species in species]
    measurement = BasicGroupMeasurement(metric, measurements)
    return measurement
end

end