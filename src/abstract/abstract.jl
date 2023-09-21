"""
Entity Types
"""

"""
    Genotype

Encodes genetic information.
"""
abstract type Genotype end

"""
    GenotypeConfiguration

Describes the configuration for generating a genotype.
"""
abstract type GenotypeConfiguration end

"""
    PhenotypeConfiguration

Transforms a genotype into a structured data representation, known as a phenotype.
"""
abstract type PhenotypeConfiguration end

"""
    Individual

Represents a single evolutionary instantiation of a genotype.
"""
abstract type Individual end

"""
    Species

A collection or group of individuals.
"""
abstract type Species end

"""
    SpeciesConfiguration

Defines the configuration for creating a species.
"""
abstract type SpeciesConfiguration end

"""
    Ecosystem

Represents a collection of species.
"""
abstract type Ecosystem end

"""
    get_pheno_dict(eco::Ecosystem)

Return a dictionary mapping individual IDs to phenotypes for a given ecosystem. Must be implemented
for specific ecosystem subtypes.
"""
function get_pheno_dict(::Ecosystem)
    throw(ErrorException("Required method `get_pheno_dict` not implemented for Ecosystem."))
end

"""
    EcosystemConfiguration

Defines the configuration for creating an ecosystem.
"""
abstract type EcosystemConfiguration end 

"""
Interaction Types
"""

"""
    Problem

Represents a task or challenge to be addressed by entities.
"""
abstract type Problem end

"""
    MatchMaker

Chooses or designates specific entities to tackle or address a problem.
"""
abstract type MatchMaker end

"""
    Observation

Encapsulates data or insights produced from an interaction between entities.
"""
abstract type Observation end

"""
    ObservationConfiguration

Specifies the type and nature of data to be collected from an interaction.
"""
abstract type ObservationConfiguration end

"""
    interact(problem::Problem, domain_id::Int, obs_cfg::ObservationConfiguration, args...)

Facilitate an interaction between entities and return the observed results. 
To be implemented for specific problem subtypes.
"""
function interact(problem::Problem, domain_id::Int, obs_cfg::ObservationConfiguration, args...)
    throw(ErrorException("Required method `interact` not implemented for Problem."))
end

"""
    DomainConfiguration

Defines the configuration of an interactive domain or environment.
"""
abstract type DomainConfiguration end

"""
    Job

Describes a unit or piece of evaluation work that a worker needs to execute.
"""
abstract type Job end

"""
    JobConfiguration

Lays out a series of jobs or tasks that need to be undertaken.
"""
abstract type JobConfiguration end

"""
Genetic Algorithm and Reproduction Types
"""

"""
    Evaluation

Stores the evaluation or assessment information for an individual.
"""
abstract type Evaluation end

"""
    EvaluationConfiguration

Specifies the configuration for carrying out evaluations.
"""
abstract type EvaluationConfiguration end

"""
    Replacer

Enables replacement of one generation of a population with the next.
"""
abstract type Replacer end

"""
    Selector

Picks or chooses parents from a population based on certain criteria.
"""
abstract type Selector end

"""
    Recombiner

Facilitates generation of offspring from the selected set of parents.
"""
abstract type Recombiner end

"""
    Mutator

Introduces genetic mutations into offspring.
"""
abstract type Mutator end

"""
Analysis Types
"""

"""
    Archivist

Responsible for logging, storing, and managing data produced through the coevolutionary process.
"""
abstract type Archivist end

"""
    ArchivistConfiguration

Defines the configuration for an archivist, detailing how it should handle and store data.
"""
abstract type ArchivistConfiguration end

"""
Utility Types
"""

"""
    Sense

Determines whether we aim to minimize or maximize a value when assessing fitness.
"""
abstract type Sense end
