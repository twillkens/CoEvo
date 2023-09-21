"""
    SpeciesConfigurations

This module provides tools and configurations for defining and handling species
in a co-evolutionary ecosystem.
"""
module SpeciesConfigurations

# Exported types and functions
export SpeciesCfg

# Dependencies
include("individuals/individuals.jl")
include("pheno_cfgs/pheno_cfgs.jl")
include("evaluations/evaluations.jl")
include("replacers/replacers.jl")
include("selectors/selectors.jl")
include("recombiners/recombiners.jl")
include("mutators/mutators.jl")

# External modules and libraries
using Random: AbstractRNG
using DataStructures: OrderedDict
using ..CoEvo: Species, Individual, EvaluationConfiguration
using ..CoEvo: SpeciesConfiguration, PhenotypeConfiguration, GenotypeConfiguration
using ..CoEvo: Replacer, Selector, Recombiner, Mutator, Replacer
using ..CoEvo.Utilities: Counter, next!
using ..CoEvo.Substrates: VectorGenoCfg
using .Individuals: Indiv
using .PhenotypeConfigurations: DefaultPhenoCfg
using .Evaluations: ScalarFitnessEvalCfg
using .Replacers: IdentityReplacer
using .Selectors: IdentitySelector
using .Recombiners: CloneRecombiner
using .Mutators: Mutator
using ..CoEvo.Interactions: InteractionResult 

"""
    BasicSpecies{P <: PhenotypeConfiguration, I <: Individual}

A collection of individuals that represents a species population and its children.

# Fields
- `id::String`: A unique identifier for the species.
- `pheno_cfg::P`: Configuration for the phenotype.
- `pop::OrderedDict{Int, I}`: The current population of individuals.
- `children::OrderedDict{Int, I}`: The children of the population.
"""
struct BasicSpecies{P <: PhenotypeConfiguration, I <: Individual} <: Species
    id::String
    pheno_cfg::P
    pop::OrderedDict{Int, I}
    children::OrderedDict{Int, I}
end

# Constructors
function BasicSpecies(
    id::String, pheno_cfg::PhenotypeConfiguration, 
    pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    BasicSpecies(
        id,
        pheno_cfg,
        OrderedDict(indiv.id => indiv for indiv in pop),
        OrderedDict(indiv.id => indiv for indiv in children)
    )
end

function BasicSpecies(id::String, pop::OrderedDict{Int, I}) where {I <: Individual}
    return BasicSpecies(id, DefaultPhenoCfg(), pop, OrderedDict{Int, I}())
end

function BasicSpecies(
    id::String, pheno_cfg::PhenotypeConfiguration, pop::OrderedDict{Int, I}
) where {I <: Individual}
    return BasicSpecies(id, pheno_cfg, pop, OrderedDict{Int, I}())
end

"""
    SpeciesCfg

Configuration for generating a new species in the ecosystem.

# Fields
- `id::String`: A unique identifier for the species.
- `n_pop::Int`: Size of the population.
- `geno_cfg::G`: Genotype configuration.
- `pheno_cfg::P`: Phenotype configuration.
- `eval_cfg::E`: Evaluation configuration.
- `replacer::RP`: Mechanism for replacing old individuals with new ones.
- `selector::S`: Mechanism for selecting parents for reproduction.
- `recombiner::RC`: Mechanism for recombination (e.g., crossover).
- `mutators::Vector{M}`: A list of mutation mechanisms.
"""
@Base.kwdef mutable struct SpeciesCfg{
    G <: GenotypeConfiguration, 
    P <: PhenotypeConfiguration, 
    E <: EvaluationConfiguration,
    RP <: Replacer, 
    S <: Selector,
    RC <: Recombiner, 
    M <: Mutator
} <: SpeciesConfiguration
    id::String = "default"
    n_pop::Int = 10 
    geno_cfg::G = VectorGenoCfg()
    pheno_cfg::P = DefaultPhenoCfg()
    eval_cfg::E = ScalarFitnessEvalCfg()
    replacer::RP = IdentityReplacer()
    selector::S = IdentitySelector()
    recombiner::RC = CloneRecombiner()
    mutators::Vector{M} = Mutator[]
end

"""
Generate a new population of individuals using genotype and phenotype configurations.

# Arguments
- `cfg::SpeciesCfg`: Configuration for the species.
- `rng::AbstractRNG`: Random number generator.
- `indiv_id_counter::Counter`: Counter for generating unique individual IDs.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.
"""
function(cfg::SpeciesCfg)(
    rng::AbstractRNG, 
    indiv_id_counter::Counter = Counter(),
    gene_id_counter::Counter = Counter()
)::Species
    indiv_ids = next!(indiv_id_counter, cfg.n_pop)
    genos = cfg.geno_cfg(rng, gene_id_counter, cfg.n_pop) 
    pop = OrderedDict(
        indiv_id => Indiv(indiv_id, geno) 
        for (indiv_id, geno) in zip(indiv_ids, genos)
    )
    BasicSpecies(cfg.id, cfg.pheno_cfg, pop)
end

"""
Core reproduction phase of the evolutionary algorithm.

# Arguments
- `cfg::SpeciesCfg`: Configuration for the species.
- `rng::AbstractRNG`: Random number generator.
- `indiv_id_counter::Counter`: Counter for generating unique individual IDs.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.
- `species::Species`: Current species.
- `results::Vector{<:InteractionResult`: Interaction results of the individuals.

# Returns
- A new `BasicSpecies` containing the next generation population and their children.
"""
function(cfg::SpeciesCfg)(
    rng::AbstractRNG, 
    indiv_id_counter::Counter,  
    gene_id_counter::Counter,  
    species::Species, 
    results::Vector{<:InteractionResult}
)::BasicSpecies
    evaluations = cfg.eval_cfg(species, results)
    pop = cfg.replacer(rng, species, evaluations)
    parents = cfg.selector(rng, pop, evaluations)
    children = cfg.recombiner(rng, indiv_id_counter, parents)
    for mutator in cfg.mutators
        children = mutator(rng, gene_id_counter, children)
    end
    return BasicSpecies(cfg.id, cfg.pheno_cfg, pop, children)
end

end
