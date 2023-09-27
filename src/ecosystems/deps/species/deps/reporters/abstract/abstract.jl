module Abstract

export SpeciesReport, SpeciesReporter

abstract type SpeciesReporter <: Reporter end
abstract type SpeciesReport <: Report end


end