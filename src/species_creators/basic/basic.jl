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
using ...Mutators: Mutator, mutate
using ..SpeciesCreators: SpeciesCreator

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
    random_number_generator::AbstractRNG, 
    individual_id_counter::Counter,
    gene_id_counter::Counter
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

function create_species(
    species_creator::BasicSpeciesCreator,
    random_number_generator::AbstractRNG, 
    individual_id_counter::Counter,  
    gene_id_counter::Counter,  
    species::BasicSpecies,
    evaluation::Evaluation
) 
    new_population = replace(
        species_creator.replacer, random_number_generator, species, evaluation
    )
    parents = select(
        species_creator.selector, random_number_generator, new_population, evaluation
    )
    new_children = recombine(
        species_creator.recombiner, random_number_generator, individual_id_counter, parents
    )
    for mutator in species_creator.mutators
        new_children = mutate(mutator, random_number_generator, gene_id_counter, new_children)
    end
    new_species = BasicSpecies(species_creator.id, new_population, new_children)
    return new_species
end

function get_individuals(species::BasicSpecies, ids::Vector{Int})
    all_individuals = [species.population ; species.children]
    individuals = get_individuals(all_individuals, ids)
    return individuals
end

function get_individuals(species::BasicSpecies)
    individuals = [species.population ; species.children]
    return individuals
end

end