module Basic

export BasicSpecies, BasicSpeciesCreator

using Random: AbstractRNG
using DataStructures: OrderedDict

using ...Ecosystems.Utilities.Counters: Counter, next!
using ..Abstract: AbstractSpecies, SpeciesCreator
using ...Individuals.Abstract: Individual
using ...Individuals.Interfaces: create_individuals
using ...Genotypes.Abstract: GenotypeCreator
using ...Phenotypes.Abstract: PhenotypeCreator
using ...Evaluators.Abstract: Evaluator, Evaluation
using ...Replacers.Abstract: Replacer
using ...Replacers.Interfaces: replace
using ...Selectors.Abstract: Selector
using ...Selectors.Interfaces: select
using ...Recombiners.Abstract: Recombiner
using ...Recombiners.Interfaces: recombine
using ...Mutators.Abstract: Mutator
using ...Mutators.Interfaces: mutate

import ..Species.Interfaces: create_species

"""
    BasicSpecies{P <: PhenotypeCreator, I <: Individual}

Represents a species population and its offspring.

# Fields
- `id::String`: Unique species identifier.
- `phenotype_creator::P`: Phenotype configuration.
- `population::OrderedDict{Int, I}`: Current population.
- `children::OrderedDict{Int, I}`: Offspring of the population.
"""
struct BasicSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    children::Vector{I}
end

"""
    BasicSpeciesCreator{...}

Defines the parameters for species generation.

# Fields
- `id::String`: A unique identifier for the species.
- `n_population::Int`: Size of the population.
- `genotype_creator::G`: Genotype configuration.
- `phenotype_creator::P`: Phenotype configuration.
- `indiv_creator::I`: Individual configuration.
- `evaluator::E`: Evaluation configuration.
- `replacer::RP`: Mechanism for replacing old individuals with new ones.
- `selector::S`: Mechanism for selecting parents for reproduction.
- `recombiner::RC`: Mechanism for recombination (e.g., crossover).
- `mutators::Vector{M}`: A list of mutation mechanisms.
- `reporters::Vector{R}`: A list of reporters for gathering species metrics.
"""
Base.@kwdef struct BasicSpeciesCreator{
    G <: GenotypeCreator,
    I <: IndividualCreator,
    P <: PhenotypeCreator,
    E <: Evaluator,
    RP <: Replacer,
    S <: Selector,
    RC <: Recombiner,
    M <: Mutator,
} <: SpeciesCreator
    id::String
    n_population::Int
    n_children::Int
    genotype_creator::G
    individual_creator::I
    phenotype_creator::P
    evaluator::E
    replacer::RP
    selector::S
    recombiner::RC
    mutators::Vector{M}
end

"""
Generate a new population of individuals using genotype and phenotype configurations.

# Arguments
- `creator::SpeciesCfg`: Creator for the species.
- `random_number_generator::AbstractRNG`: Random number generator.
- `individual_id_counter::Counter`: Counter for generating unique individual IDs.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.
"""
function create_species(
    species_creator::BasicSpeciesCreator,
    random_number_generator::AbstractRNG, 
    individual_id_counter::Counter = Counter(),
    gene_id_counter::Counter = Counter(),
)
    population = create_individuals(
        species_creator.individual_creator, 
        random_number_generator, 
        species_creator.genotype_creator, 
        species_creator.n_population, 
        individual_id_counter, 
        gene_id_counter
    )
    children = create_individuals(
        species_creator.individual_creator, 
        random_number_generator, 
        species_creator.genotype_creator, 
        species_creator.n_children, 
        individual_id_counter, 
        gene_id_counter
    )
    species = BasicSpecies(species_creator.id, population, children)
    return species
end

"""
Core reproduction phase of the evolutionary algorithm.

# Arguments
- `creator::SpeciesCfg`: Creator for the species.
- `random_number_generator::AbstractRNG`: Random number generator.
- `individual_id_counter::Counter`: Counter for generating unique individual IDs.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.
- `species::Species`: Current species.
- `results::Vector{<:InteractionResult`: Interaction results of the individuals.

# Returns
- A new `BasicSpecies` containing the next generation population and their children.
"""
function create_species(
    species_creator::BasicSpeciesCreator,
    random_number_generator::AbstractRNG, 
    individual_id_counter::Counter,  
    gene_id_counter::Counter,  
    species::AbstractSpecies,
    evaluation::Evaluation
) 
    new_population = replace(species_creator.replacer, random_number_generator, species, evaluation)
    parents = select(species_creator.selector, random_number_generator, new_population, evaluation)
    new_children = recombine(species_creator.recombiner, random_number_generator, individual_id_counter, parents)
    for mutator in species_creator.mutators
        new_children = mutate(mutator, random_number_generator, gene_id_counter, new_children)
    end
    new_species = BasicSpecies(species_creator.id, new_population, new_children)
    return new_species
end

end