module Basic

export BasicSpeciesCreator

import ...Individuals: get_individuals
import ..SpeciesCreators: create_species

using Random: AbstractRNG
using DataStructures: OrderedDict
using ...Counters: Counter
using ...Individuals: Individual, IndividualCreator, create_individuals
using ...Genotypes: GenotypeCreator
using ...Phenotypes: PhenotypeCreator
using ...Species.Basic: BasicSpecies
using ...Evaluators: Evaluator, Evaluation
using ...Replacers: Replacer, replace
using ...Selectors: Selector, select
using ...Recombiners: Recombiner, recombine
using ...Recombiners.Clone: CloneRecombiner
using ...Mutators: mutate
using ...Abstract
using ..SpeciesCreators: SpeciesCreator
using ...Abstract.States: State, get_rng, get_individual_id_counter, get_gene_id_counter

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

function create_species(
    species_creator::BasicSpeciesCreator,
    rng::AbstractRNG, 
    individual_id_counter::Counter,
    gene_id_counter::Counter
)
    population = create_individuals(
        species_creator.individual_creator, 
        rng, 
        species_creator.genotype_creator, 
        species_creator.n_population, 
        individual_id_counter, 
        gene_id_counter
    )
    children = create_individuals(
        species_creator.individual_creator, 
        rng, 
        species_creator.genotype_creator, 
        species_creator.n_population, 
        individual_id_counter, 
        gene_id_counter
    )
    #children = recombine(
    #    species_creator.recombiner, 
    #    rng, 
    #    individual_id_counter, 
    #    population
    #)
    species = BasicSpecies(species_creator.id, population, children)
    return species
end

function create_species(
    species_creator::BasicSpeciesCreator, 
    state::State
)
    species = create_species(
        species_creator, 
        get_rng(state), 
        get_individual_id_counter(state),
        get_gene_id_counter(state)
    )

    return species
end
    

function create_species(
    species_creator::BasicSpeciesCreator,
    rng::AbstractRNG, 
    individual_id_counter::Counter,  
    gene_id_counter::Counter,  
    species::BasicSpecies,
    evaluation::Evaluation
) 
    #println("------$(species.id)-----")
    new_population = replace(
        species_creator.replacer, rng, species, evaluation
    )
    #println("new_population_ids = ", [individual.id for individual in new_population])
    #println("rng state = ", rng.state)
    parents = select(
        species_creator.selector, rng, new_population, evaluation
    )
    #println("parents_ids = ", [individual.id for individual in parents])
    #println("rng state = ", rng.state)
    new_children = recombine(
        species_creator.recombiner, rng, individual_id_counter, parents
    )
    #println("new_children_ids = ", [individual.id for individual in new_children])
    #println("rng state = ", rng.state)
    for mutator in species_creator.mutators
        new_children = mutate(mutator, rng, gene_id_counter, new_children)
    end
    #println("new_mutant_ids = ", [individual.id for individual in new_children])
    #println("rng state = ", rng.state)

    # TODO: This is a hack to make sure that the parent IDs are set for MODES.
    for individual in new_population
        individual.parent_ids[1] = individual.id
    end
    new_species = BasicSpecies(species_creator.id, new_population, new_children)
    return new_species
end

using ...Abstract.States: find_by_id

function create_species(
    species_creator::BasicSpeciesCreator, 
    species::BasicSpecies, 
    state::State
)
    evaluation = find_by_id(state.evaluations,species.id,  )
    species = create_species(
        species_creator, 
        get_rng(state), 
        get_individual_id_counter(state),
        get_gene_id_counter(state),
        species, 
        evaluation
    )

    return species
end


end