module Abstract

export AbstractRNG
export Counter
export Gene, Genotype, GenotypeCreator
export Phenotype, PhenotypeCreator
export Individual, IndividualCreator
export AbstractSpecies
export Criterion
export Clusterer
export Evaluator, Evaluation, Record
export Replacer
export Selector, Selection
export Recombiner
export Mutator
export SpeciesCreator
export Metric, Measurement, Aggregator
export Domain
export Match
export MatchMaker
export Observation, Observer, PhenotypeObserver
export Result
export Environment, EnvironmentCreator
export Interaction
export Job, JobCreator
export Performer
export Ecosystem, EcosystemCreator
export Archiver
export Reproducer
export Simulator
export State, StateCreator
export Configuration

using Random: AbstractRNG

abstract type Counter end

abstract type Gene end

abstract type Genotype end

abstract type GenotypeCreator end

abstract type Phenotype end

abstract type PhenotypeCreator end

abstract type PhenotypeState end

abstract type Individual end

abstract type IndividualCreator end

abstract type AbstractSpecies end

abstract type Criterion end

abstract type Clusterer end

abstract type Evaluation end

abstract type Evaluator end

abstract type Record end

abstract type Replacer end

abstract type Selector end

abstract type Selection end

abstract type Recombiner end

abstract type Mutator end

abstract type SpeciesCreator end

abstract type Metric end

abstract type Measurement end

abstract type Aggregator end

abstract type Domain{M <: Metric} end

abstract type Match end

abstract type MatchMaker end

abstract type Observation end

abstract type Observer end

abstract type PhenotypeObserver <: Observer end

abstract type Result end

abstract type Environment{D <: Domain} end

abstract type EnvironmentCreator{D <: Domain} end

abstract type Interaction end

abstract type Job end

abstract type JobCreator end 

abstract type Performer end

abstract type Ecosystem end

abstract type EcosystemCreator end

abstract type Archiver end

abstract type Reproducer end

abstract type Simulator end

abstract type State end

abstract type StateCreator end

abstract type Configuration end

end
