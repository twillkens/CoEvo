abstract type Individual end
abstract type Genotype end
abstract type GenotypeConfiguration end
abstract type Phenotype end
abstract type PhenotypeConfiguration end
abstract type SpeciesConfiguration end

struct Indiv{G <: Genotype} <: Individual
    id::Int
    geno::G
    pid::Int
end

Indiv(id::Int, geno::Genotype) = Indiv(id, geno, 0)


struct DefaultPhenoCfg <: PhenotypeConfiguration end

function(cfg::DefaultPhenoCfg)(geno::Genotype)
    geno
end

"""
    Species{I <: Individual}(id::String, pop::Dict{Int, I}, children::Dict{Int, I})

A collection of individuals comprising a population and their children.

# Fields
- `id::String`: Unique identifier for the species
- `pop::Dict{Int, I}`: The population of individuals, where the key is the individual's id
- `children::Dict{Int, I}`: The children of the population, where the key is the individual's id
"""
struct Species{P <: PhenotypeConfiguration, I <: Individual}
    id::String
    pheno_cfg::P
    pop::OrderedDict{Int, I}
    children::OrderedDict{Int, I}
end

function Species(id::String, pop::Vector{<:Individual}, children::Vector{<:Individual})
    Species(
        id,
        OrderedDict(indiv.id => indiv for indiv in pop),
        OrderedDict(indiv.id => indiv for indiv in children)
    )
end

"""
    SpeciesCfg(
        id::String = "species",
        n_indiv::Int = 10,
        genocfg::GenotypeConfiguration = GPGenoCfg(),
        phenocfg::PhenotypeConfiguration = DefaultPhenoCfg(),
        replacer::Replacer = IdentityReplacer(),
        selector::Selector = IdentitySelector(),
        recombiner::Recombiner = IdentityRecombiner(),
        mutators::Vector{Mutator} = Mutator[],
    )

    Return a Species object comprising the initial population for a species in the ecosystem.

    # Arguments
    - `id::String`: Unique identifier for the species
    - `n_indiv::Int`: Number of individuals to spawn
    - `genocfg::GenotypeConfiguration`: Configuration for generating genotypes
    - `phenocfg::PhenotypeConfiguration`: Configuration for generating phenotypes from the genotypes
    - `replacer::Replacer`: Pick members of the previous population to keep or replace with children
    - `selector::Selector`: Select members of the previous population to use as parents
    - `recombiner::Recombiner`: Generate children from the selected parents
    - `mutators::Vector{Mutator}`: Mutate each children sequentially ith the given mutators
    - `curr_indiv_id::Int`: The current individual id to use when generating new individuals
    - `curr_gene_id::Int`: The current gene id to use when generating new genes for an individual
"""

abstract type Replacer end
abstract type Selector end
abstract type Recombiner end
abstract type Mutator end


@Base.kwdef mutable struct SpeciesCfg{
    G <: GenotypeConfiguration, 
    P <: PhenotypeConfiguration, 
    RP <: Replacer, 
    S <: Selector,
    RC <: Recombiner, 
    M <: Mutator
} <: SpeciesConfiguration
    id::String = "species"
    n_pop::Int = 10 
    geno_cfg::G # = GPGenoCfg()
    pheno_cfg::P # = DefaultPhenoCfg()
    replacer::RP # = IdentityReplacer()
    selector::S # = IdentitySelector()
    recombiner::RC # = IdentityRecombiner()
    mutators::Vector{M} = Mutator[]
end


"""
    cfg(rng::AbstractRNG) 

"""

function Species(id::String, pop::OrderedDict{Int, I}) where {I <: Individual}
    Species(id, pop, Dict{Int, I}())
end


"""
Generate a new population of individuals for the species using the genotype configuration.
Individual and gene ids are generated using the given counters.
"""
function(cfg::SpeciesCfg)(
    rng::AbstractRNG, 
    indiv_id_counter::Counter = Counter(),
    gene_id_counter::Counter = Counter()
)::Species
    indiv_ids = next!(indiv_id_counter, s.n_pop)
    genos = cfg.geno_cfg(rng, gene_id_counter, s.n_pop) 
    pop = OrderedDict(
        indiv_id => Indiv(indiv_id, geno) 
        for (indiv_id, geno) in zip(indiv_ids, genos)
    )
    Species(cfg.id, cfg.pheno_cfg, pop)
end

abstract type Record end


# This fulfills the core reproduction phase of the evolutionary algorithm
# Given an input of a Species of veterans, the spawner will generate a new Species
# of children. 
# * The Replacer determines which members of the previous population 
#   and their children survive to form the population of the next generation.
# * The Selector determines which members of the previous population are selected
#   to serve as parents for the next generation. Parents come as a vector of 
#   Veterans; the presence of one parent multiple times indicates .
# * The Recombiner may either generate a single child from crossover of some set taken from
#   the parents; the IdentityRecombiner simply returns the parents as cloned children.
# * For each Mutator, the children are mutated according to the mutator's parameters.
#   The mutators are applied in the order they are given in the spawner.
# Finally, the newly selected population along with their children are returned as a Species.
function(cfg::SpeciesCfg)(
    rng::AbstractRNG, 
    indiv_id_counter::Counter,  
    gene_id_counter::Counter,  
    species::Species, 
    records::Dict{Int, <:Record}
)::Species
    pop = cfg.replacer(rng, species, records)
    parents = cfg.selector(rng, pop, records)
    children = cfg.recombiner(rng, indiv_id_counter, parents)
    for mutator in cfg.mutators
        children = mutator(rng, gene_id_counter, children)
    end
    Species(cfg.id, cfg.pheno_cfg, pop, children)
end