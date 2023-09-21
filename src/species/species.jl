module SpeciesTypes

export SpeciesCfg

include("individuals/individuals.jl")
include("pheno_cfgs/pheno_cfgs.jl")
include("evaluations/evaluations.jl")
include("replacers/replacers.jl")
include("selectors/selectors.jl")
include("recombiners/recombiners.jl")
include("mutators/mutators.jl")

using Random: AbstractRNG
using DataStructures: OrderedDict
using ..CoEvo: Species, Individual, EvaluationConfiguration
using ..CoEvo: SpeciesConfiguration, PhenotypeConfiguration, GenotypeConfiguration
using ..CoEvo: Replacer, Selector, Recombiner, Mutator, Replacer
using ..CoEvo.Utilities: Counter
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
    Species{I <: Individual}(id::String, pop::Dict{Int, I}, children::Dict{Int, I})

A collection of individuals comprising a population and their children.

# Fields
- `id::String`: Unique identifier for the species
- `pop::Dict{Int, I}`: The population of individuals, where the key is the individual's id
- `children::Dict{Int, I}`: The children of the population, where the key is the individual's id
"""
struct BasicSpecies{P <: PhenotypeConfiguration, I <: Individual} <: Species
    id::String
    pheno_cfg::P
    pop::OrderedDict{Int, I}
    children::OrderedDict{Int, I}
end

function BasicSpecies(id::String, pop::Vector{<:Individual}, children::Vector{<:Individual})
    BasicSpecies(
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
@Base.kwdef mutable struct SpeciesCfg{
    G <: GenotypeConfiguration, 
    P <: PhenotypeConfiguration, 
    E <: EvaluationConfiguration,
    RP <: Replacer, 
    S <: Selector,
    RC <: Recombiner, 
    M <: Mutator
} <: SpeciesConfiguration
    id::String = "species"
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
    cfg(rng::AbstractRNG) 

"""

function BasicSpecies(id::String, pop::OrderedDict{Int, I}) where {I <: Individual}
    return BasicSpecies(id, pop, Dict{Int, I}())
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
    BasicSpecies(cfg.id, cfg.pheno_cfg, pop)
end



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