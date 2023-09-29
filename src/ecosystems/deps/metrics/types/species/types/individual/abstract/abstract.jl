module Abstract

export IndividualMetric

using ...Abstract: SpeciesMetric

abstract type IndividualMetric <: SpeciesMetric end

end