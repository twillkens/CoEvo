export Entity, Domain, Atom
export Aspect, Phenotype, Genotype, Organism
export Population, Domain, Recipe, Mix
export Outcome, Statistics, Coevolution
export Ingredient, Order, TypeWrapper, PairOrder
export Job, JobConfig
export GenoConfig, PopConfig, OrderConfig, PhenoConfig
export Selections, Reproducer, Record, Selector, PairOutcome
export Result
export Variator
export Individual

# top level
abstract type Entity end

# entity that cannot be composed into subentities
abstract type Atom <: Entity end

abstract type Aspect end

# datatype of the "DNA" or information for encoding an entity
abstract type Genotype <: Atom end

# datatype of the "expression" of the genotype, used for evaluation
abstract type Phenotype <: Atom end

# atomic entity comprising a genotype and a phenotype
#abstract type Organism{G <: Genotype, P <: Phenotype} <: Atom end

# a set of entities (which itself constitutes an entity)
abstract type Population <: Entity end

# a mode of interaction between entities
abstract type Domain end

# a means of determining which entities interact 
abstract type Recipe end

abstract type Ingredient end

abstract type Order end

# specifies (1) a set of entities or their keys, (2) the domain in which they interact
abstract type Mix end

abstract type Ecosystem end

# an outcome of an interaction
abstract type Outcome end

# statistics associated with an entity
abstract type Statistics end

# driver
abstract type Coevolution <: Entity end

abstract type TypeWrapper end

abstract type PairOrder <: Order end

abstract type Job end

abstract type Config end

abstract type JobConfig <: Config end
abstract type GenoConfig <: Config end
abstract type PhenoConfig <: Config end
abstract type PopConfig <: Config end
abstract type OrderConfig <: Config end
abstract type Selector <: Config end
abstract type Record end

abstract type Reproducer end
abstract type Selections end
abstract type Logger end
abstract type PairOutcome <: Outcome end
abstract type Result end
abstract type Archiver end
abstract type Variator end
abstract type Individual end
