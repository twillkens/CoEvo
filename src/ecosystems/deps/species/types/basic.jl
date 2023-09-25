export BasicSpecies, BasicSpeciesConfiguration

using Random: AbstractRNG
using DataStructures: OrderedDict
using ...CoEvo.Abstract: AbstractSpecies, SpeciesConfiguration, PhenotypeConfiguration
using ...CoEvo.Abstract: GenotypeConfiguration, EvaluationConfiguration, Replacer
using ...CoEvo.Abstract: Selector, Recombiner, Mutator, Individual, Evaluation
using ...CoEvo.Abstract: IndividualConfiguration, Reporter, Report
using ...CoEvo.Utilities.Counters: Counter, next!
using .Genotypes: VectorGenotypeConfiguration
using .Phenotypes: DefaultPhenotypeConfiguration
using .Individuals: AsexualIndividualConfiguration
using .Evaluations: ScalarFitnessEvaluationConfiguration


"""
    BasicSpecies{P <: PhenotypeConfiguration, I <: Individual}

A collection of individuals that represents a species population and its children.

# Fields
- `id::String`: A unique identifier for the species.
- `pheno_cfg::P`: Configuration for the phenotype.
- `pop::OrderedDict{Int, I}`: The current population of individuals.
- `children::OrderedDict{Int, I}`: The children of the population.
"""
struct BasicSpecies{P <: PhenotypeConfiguration, I <: Individual} <: AbstractSpecies
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
    return BasicSpecies(
        id,
        pheno_cfg,
        OrderedDict(indiv.id => indiv for indiv in pop),
        OrderedDict(indiv.id => indiv for indiv in children)
    )
end

function BasicSpecies(id::String, pop::OrderedDict{Int, I}) where {I <: Individual}
    return BasicSpecies(
        id, 
        DefaultPhenotypeConfiguration(), 
        pop, 
        OrderedDict{Int, I}(), 
    )
end

function BasicSpecies(
    id::String, pheno_cfg::PhenotypeConfiguration, pop::OrderedDict{Int, I}
) where {I <: Individual}
    return BasicSpecies(
        id, 
        pheno_cfg, 
        pop, 
        OrderedDict{Int, I}(), 
    )
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
@Base.kwdef struct BasicSpeciesConfiguration{
    G <: GenotypeConfiguration, 
    P <: PhenotypeConfiguration, 
    I <: IndividualConfiguration,
    E <: EvaluationConfiguration,
    RP <: Replacer, 
    S <: Selector,
    RC <: Recombiner, 
    M <: Mutator,
    R <: Reporter
} <: SpeciesConfiguration
    id::String
    n_pop::Int
    geno_cfg::G
    pheno_cfg::P
    indiv_cfg::I
    eval_cfg::E
    replacer::RP
    selector::S
    recombiner::RC
    mutators::Vector{M}
    reporters::Vector{R}
end

"""
Generate a new population of individuals using genotype and phenotype configurations.

# Arguments
- `cfg::SpeciesCfg`: Configuration for the species.
- `rng::AbstractRNG`: Random number generator.
- `indiv_id_counter::Counter`: Counter for generating unique individual IDs.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.
"""
function(species_cfg::BasicSpeciesConfiguration)(
    rng::AbstractRNG, 
    indiv_id_counter::Counter = Counter(),
    gene_id_counter::Counter = Counter()
)
    indiv_ids = next!(indiv_id_counter, species_cfg.n_pop)
    genos = species_cfg.geno_cfg(rng, gene_id_counter, species_cfg.n_pop) 
    pop = OrderedDict(
        indiv_id => species_cfg.indiv_cfg(indiv_id, geno) 
        for (indiv_id, geno) in zip(indiv_ids, genos)
    )
    return BasicSpecies(species_cfg.id, species_cfg.pheno_cfg, pop)
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
function(species_cfg::BasicSpeciesConfiguration)(
    rng::AbstractRNG, 
    indiv_id_counter::Counter,  
    gene_id_counter::Counter,  
    pop_evals::OrderedDict{<:Individual, <:Evaluation},
    children_evals::OrderedDict{<:Individual, <:Evaluation},
) 
    new_pop_evals = species_cfg.replacer(rng, pop_evals, children_evals)
    parents = species_cfg.selector(rng, new_pop_evals)
    new_children = species_cfg.recombiner(rng, indiv_id_counter, parents)
    for mutator in species_cfg.mutators
        new_children = mutator(rng, gene_id_counter, new_children)
    end
    new_pop = OrderedDict(indiv.id => indiv for indiv in keys(new_pop_evals))
    new_children = OrderedDict(indiv.id => indiv for indiv in new_children)
    new_species = BasicSpecies(species_cfg.id, species_cfg.pheno_cfg, new_pop, new_children)
    return new_species
end