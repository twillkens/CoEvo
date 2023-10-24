module Abstract

export Environment, EnvironmentCreator

using ...Domains.Abstract: Domain
#using ....Species.Phenotypes.Abstract: Phenotype

#abstract type Environment{D <: Domain, P <: Phenotype} end
abstract type Environment{D <: Domain} end

abstract type EnvironmentCreator{D <: Domain} end

end