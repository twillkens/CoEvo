module Basic

export BasicSpecies, BasicSpeciesCreator

using Random: AbstractRNG
using DataStructures: OrderedDict

using ...Ecosystems.Utilities.Counters: Counter, next!
using ..Abstract: AbstractSpecies, SpeciesCreator
using ..Individuals: Individual
using ..Species.Genotypes.Abstract: GenotypeCreator
using ..Species.Genotypes.Interfaces: create_genotypes
using ..Species.Phenotypes.Abstract: PhenotypeCreator
using ..Species.Evaluators.Abstract: Evaluator, Evaluation
using ..Species.Replacers.Abstract: Replacer
using ..Species.Replacers.Interfaces: replace
using ..Species.Selectors.Abstract: Selector
using ..Species.Selectors.Interfaces: select
using ..Species.Recombiners.Abstract: Recombiner
using ..Species.Recombiners.Interfaces: recombine
using ..Species.Mutators.Abstract: Mutator
using ..Species.Mutators.Interfaces: mutate

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

function BasicSpecies(id::String, population::Vector{I}) where {I <: Individual}
    species = BasicSpecies(id, population, I[])
    return species
end



"""
    BasicSpeciesCreator{...}

Defines the parameters for species generation.

# Fields
- `id::String`: A unique identifier for the species.
- `n_pop::Int`: Size of the population.
- `geno_creator::G`: Genotype configuration.
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
    P <: PhenotypeCreator,
    E <: Evaluator,
    RP <: Replacer,
    S <: Selector,
    RC <: Recombiner,
    M <: Mutator,
} <: SpeciesCreator
    id::String
    n_pop::Int
    geno_creator::G
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
- `rng::AbstractRNG`: Random number generator.
- `indiv_id_counter::Counter`: Counter for generating unique individual IDs.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.
"""
function create_species(
    species_creator::BasicSpeciesCreator,
    rng::AbstractRNG, 
    indiv_id_counter::Counter = Counter(),
    gene_id_counter::Counter = Counter(),
)
    genos = create_genotypes(
        species_creator.geno_creator, rng, gene_id_counter, species_creator.n_pop
    ) 
    indiv_ids = next!(indiv_id_counter, species_creator.n_pop)
    population = [Individual(individual_id, geno, Int[]) for (individual_id, geno) in zip(indiv_ids, genos)]
    genos = create_genotypes(
        species_creator.geno_creator, rng, gene_id_counter, species_creator.n_pop
    ) 
    indiv_ids = next!(indiv_id_counter, species_creator.n_pop)
    children = [Individual(individual_id, geno, Int[]) for (individual_id, geno) in zip(indiv_ids, genos)]
    species = BasicSpecies(species_creator.id, population, children)
    return species
end

"""
Core reproduction phase of the evolutionary algorithm.

# Arguments
- `creator::SpeciesCfg`: Creator for the species.
- `rng::AbstractRNG`: Random number generator.
- `indiv_id_counter::Counter`: Counter for generating unique individual IDs.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.
- `species::Species`: Current species.
- `results::Vector{<:InteractionResult`: Interaction results of the individuals.

# Returns
- A new `BasicSpecies` containing the next generation population and their children.
"""
function create_species(
    species_creator::BasicSpeciesCreator,
    rng::AbstractRNG, 
    indiv_id_counter::Counter,  
    gene_id_counter::Counter,  
    species::AbstractSpecies,
    evaluation::Evaluation
) 
    new_population = replace(species_creator.replacer, rng, species, evaluation)
    parents = select(species_creator.selector, rng, new_population, evaluation)
    new_children = recombine(species_creator.recombiner, rng, indiv_id_counter, parents)
    for mutator in species_creator.mutators
        new_children = mutate(mutator, rng, gene_id_counter, new_children)
    end
    new_species = BasicSpecies(species_creator.id, new_population, new_children)
    return new_species
end

end