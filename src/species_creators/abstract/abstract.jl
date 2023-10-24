module Abstract

export AbstractSpecies, SpeciesCreator

using Random: AbstractRNG

abstract type AbstractSpecies end

abstract type SpeciesCreator end

end