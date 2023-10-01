module Basic

export BasicSpecies, BasicSpeciesCreator

using Random: AbstractRNG
using DataStructures: OrderedDict

using ...Ecosystems.Utilities.Counters: Counter, next!
using ..Abstract: AbstractSpecies, SpeciesCreator
using ..Individuals.Abstract: IndividualCreator, Individual
using ..Individuals.Genotypes.Abstract: GenotypeCreator
using ..Individuals.Phenotypes.Abstract: PhenotypeCreator
using ..Evaluators.Abstract: Evaluator, Evaluation
using ..Reproducers.Abstract: Reproducer
using ..Individuals.Mutators.Interfaces: mutate

import ..Interfaces: create_species, get_all_individuals


"""
    BasicSpecies{P <: PhenotypeCreator, I <: Individual}

Represents a species population and its offspring.

# Fields
- `id::String`: Unique species identifier.
- `pheno_creator::P`: Phenotype configuration.
- `pop::OrderedDict{Int, I}`: Current population.
- `children::OrderedDict{Int, I}`: Offspring of the population.
"""
struct BasicSpecies{P <: PhenotypeCreator, I <: Individual} <: AbstractSpecies
    id::String
    pheno_creator::P
    pop::OrderedDict{Int, I}
    children::OrderedDict{Int, I}
end

# Constructors
function BasicSpecies(
    id::String, pheno_creator::PhenotypeCreator, 
    pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    return BasicSpecies(
        id,
        pheno_creator,
        OrderedDict(indiv.id => indiv for indiv in pop),
        OrderedDict(indiv.id => indiv for indiv in children)
    )
end

function BasicSpecies(id::String, pop::OrderedDict{Int, I}) where {I <: Individual}
    return BasicSpecies(
        id, 
        DefaultPhenotypeCreator(), 
        pop, 
        OrderedDict{Int, I}(), 
    )
end

function BasicSpecies(
    id::String, pheno_creator::PhenotypeCreator, pop::OrderedDict{Int, I}
) where {I <: Individual}
    return BasicSpecies(
        id, 
        pheno_creator, 
        pop, 
        OrderedDict{Int, I}(), 
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
@Base.kwdef struct BasicSpeciesCreator{
    I <: IndividualCreator,
    E <: Evaluator,
    R <: Reproducer,
} <: SpeciesCreator
    id::String
    n_pop::Int
    indiv_creator::I
    evaluator::E
    reproducer::R
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
    gene_id_counter::Counter = Counter()
)
    indiv_ids = next!(indiv_id_counter, species_creator.n_pop)
    genos = create_genotypes(
        species_creator.geno_creator, rng, gene_id_counter, species_creator.n_pop
    ) 
    pop = OrderedDict(
        indiv_id => species_creator.indiv_creator(indiv_id, geno) 
        for (indiv_id, geno) in zip(indiv_ids, genos)
    )
    return BasicSpecies(species_creator.id, species_creator.pheno_creator, pop)
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
    new_children = reproduce(
        species_creator.reproducer,
        species_creator.indiv_creator.mutators,
        rng, 
        indiv_id_counter, 
        gene_id_counter, 
        pop_evals, 
        children_evals
    )
    new_pop = OrderedDict(indiv.id => indiv for indiv in keys(new_pop_evals))
    new_children = OrderedDict(indiv.id => indiv for indiv in new_children)
    new_species = BasicSpecies(species_creator.id, species_creator.pheno_creator, new_pop, new_children)
    return new_species
end

function get_all_individuals(species::BasicSpecies)
    return merge(species.pop, species.children)
end

end