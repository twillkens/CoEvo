module Abstract

export Environment, EnvironmentCreator, Phenotype

using .....Ecosystems.Species.Individuals.Phenotypes.Abstract: Phenotype

abstract type Environment end

abstract type EnvironmentCreator end

end