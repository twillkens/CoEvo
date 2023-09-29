module Abstract

export GenotypeMetric

using ...Abstract: SpeciesMetric

abstract type GenotypeMetric <: SpeciesMetric end

end