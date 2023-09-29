module Abstract

export Domain, DomainCreator, Phenotype

abstract type Domain end

abstract type DomainCreator end

using .....Ecosystems.Species.Individuals.Phenotypes.Abstract: Phenotype

end