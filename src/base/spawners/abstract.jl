export Entity, Domain
export Phenotype, Genotype
export Domain, Recipe, Mix
export Outcome, Coevolution
export Order
export Job, JobConfig
export Selections, Selector
export Result
export Variator
export Individual, IndivConfig
export PhenoConfig

# top level
abstract type Individual end

abstract type IndivConfig end

abstract type Gene end

# entity that cannot be composed into subentities

# datatype of the "DNA" or information for encoding an entity
abstract type Genotype end

# datatype of the "expression" of the genotype, used for evaluation
abstract type Phenotype end
abstract type PhenoConfig end

# atomic entity comprising a genotype and a phenotype
#abstract type Organism{G <: Genotype, P <: Phenotype} <: Atom end

# a mode of interaction between entities
abstract type Domain end

# a means of determining which entities interact 
# abstract type Recipe end

abstract type Order end

# specifies (1) a set of entities or their keys, (2) the domain in which they interact
# abstract type Mix end

# an outcome of an interaction
abstract type Outcome end

abstract type Logger end

# statistics associated with an entity

# driver
abstract type Coevolution end

abstract type Job end
abstract type JobConfig end

abstract type Selector end

abstract type Result end
abstract type Archiver end
abstract type Variator end

abstract type Replacer end
abstract type Recombiner end
abstract type Mutator end
