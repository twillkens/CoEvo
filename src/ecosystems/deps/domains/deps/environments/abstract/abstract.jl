module Abstract

export Environment, EnvironmentCreator, Phenotype

abstract type Environment end

abstract type EnvironmentCreator end

using .....Ecosystems.Species.Individuals.Phenotypes.Abstract: Phenotype

end