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
- `pheno_creator::P`: Phenotype configuration.
- `pop::OrderedDict{Int, I}`: Current population.
- `children::OrderedDict{Int, I}`: Offspring of the population.
"""
struct BasicSpecies{I <: Individual} <: AbstractSpecies
    id::String
    pop::Dict{Int, I}
    children::Dict{Int, I}
end

# Constructors
function BasicSpecies(
    id::String,
    pop::Vector{<:Individual},
    children::Vector{<:Individual}
)
    return BasicSpecies(
        id,
        Dict(indiv.id => indiv for indiv in pop),
        Dict(indiv.id => indiv for indiv in children)
    )
end

function BasicSpecies(id::String, pop::Dict{Int, I}) where {I <: Individual}
    return BasicSpecies(
        id, 
        pop, 
        Dict{Int, I}(), 
    )
end



"""
    BasicSpeciesCreator{...}

Defines the parameters for species generation.

# Fields
- `id::String`: A unique identifier for the species.
- `n_pop::Int`: Size of the population.
- `geno_creator::G`: Genotype configuration.
- `pheno_creator::P`: Phenotype configuration.
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
    pheno_creator::P
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
    pop = Dict(
        indiv_id => Individual(indiv_id, geno, Int[]) 
        for (indiv_id, geno) in zip(indiv_ids, genos)
    )
    return BasicSpecies(species_creator.id, pop)
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
    new_pop = replace(species_creator.replacer, rng, species, evaluation)
    parents = select(species_creator.selector, rng, new_pop, evaluation)
    new_children = recombine(species_creator.recombiner, rng, indiv_id_counter, parents)
    for mutator in species_creator.mutators
        new_children = mutate(mutator, rng, gene_id_counter, new_children)
    end
    new_children = Dict(indiv.id => indiv for indiv in new_children)
    new_species = BasicSpecies(species_creator.id, new_pop, new_children)
    return new_species
end

end