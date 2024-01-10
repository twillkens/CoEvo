module Archive

export ArchiveSpeciesCreator

import ...Individuals: get_individuals
import ..SpeciesCreators: create_species

using Random: AbstractRNG
using DataStructures: OrderedDict
using ...Counters: Counter
using ...Individuals: Individual, IndividualCreator, create_individuals
using ...Genotypes: GenotypeCreator
using ...Phenotypes: PhenotypeCreator
using ...Species.Archive: ArchiveSpecies
using ...Evaluators: Evaluator, Evaluation
using ...Replacers: Replacer, replace
using ...Selectors: Selector, select
using ...Recombiners: Recombiner, recombine
using ...Recombiners.Clone: CloneRecombiner
using ...Mutators: Mutator, mutate
using ..SpeciesCreators: SpeciesCreator
using ...Abstract.States: State, get_rng, get_individual_id_counter, get_gene_id_counter
using StatsBase: sample

Base.@kwdef struct ArchiveSpeciesCreator{
    G <: GenotypeCreator,
    I <: IndividualCreator,
    P <: PhenotypeCreator,
    E <: Evaluator,
    S <: Selector,
    RC <: Recombiner,
    M <: Mutator,
} <: SpeciesCreator
    id::String
    n_population::Int
    n_parents::Int
    n_children::Int
    n_elites::Int
    n_archive::Int
    archive_interval::Int
    max_archive_length::Int
    max_archive_matches::Int
    genotype_creator::G
    individual_creator::I
    phenotype_creator::P
    evaluator::E
    selector::S
    recombiner::RC
    mutator::M
end

function create_species(
    species_creator::ArchiveSpeciesCreator, 
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
    species = ArchiveSpecies(species_creator.id, population)
    return species
end

function create_species(species_creator::ArchiveSpeciesCreator, state::State)
    species = create_species(
        species_creator, state.rng, state.individual_id_counter, state.gene_id_counter
    )
    return species
end


function add_elites_to_archive(
    archive::Vector{<:Individual}, 
    candidates::Vector{<:Individual},
    max_archive_length::Int
)
    candidate_ids = Set([candidate.id for candidate in candidates])
    archive = filter(individual -> individual.id ∉ candidate_ids, archive)
    archive = [archive ; candidates]

    while length(archive) > max_archive_length
        # eject the first elements to maintain size
        deleteat!(archive, 1)
    end
    return archive
end

function create_species(
    species_creator::ArchiveSpeciesCreator, 
    species::ArchiveSpecies, 
    evaluation::Evaluation,
    state::State
) 
    n_population_before = length(species.population)
    #println("------$(species.id)-----")
    ordered_ids = [record.id for record in evaluation.records]
    parent_ids = Set(ordered_ids[1:species_creator.n_parents])
    parent_set = [individual for individual in species.population if individual.id in parent_ids]
    #println("parent_set_length = ", length(parent_set))
    #println("parent_set_ids = ", [individual.id for individual in parent_set])
    #println("rng state = ", rng.state)
    parents = select(species_creator.selector, parent_set, evaluation, state)
    #println("parents_length = ", length(parents))
    #println("parents_ids = ", [individual.id for individual in parents])
    #println("rng state = ", rng.state)
    new_children = recombine(species_creator.recombiner, parents, state)
    #println("new_children_length = ", length(new_children))
    #println("new_children_ids = ", [individual.id for individual in new_children])
    #println("rng state = ", rng.state)
    new_children = mutate(species_creator.mutator, new_children, state)
    if species_creator.n_elites > 0
        elite_ids = [record.id for record in evaluation.records[1:species_creator.n_elites]]
        elites = [individual for individual in species.population if individual.id in elite_ids]
        new_population = [elites ; new_children]
    else
        new_population = new_children
    end

    best_records = filter(record -> record.rank == 1 && isinf(record.crowding), evaluation.records)
    best_record = reduce(
        (record1, record2) -> record1.fitness > record2.fitness ? record1 : record2, 
        best_records
    )
    best_individual = find_by_id(species.population, best_record.id)

    new_archive = add_elites_to_archive(
        species.archive, [best_individual], species_creator.max_archive_length
    )
    if species_creator.max_archive_matches > 0
        n_archive_matches = min(species_creator.max_archive_matches, length(new_archive))
        println("n_archive_matches = ", n_archive_matches)
        new_archive_individuals = sample(state.rng, new_archive, n_archive_matches)
        new_archive_ids = [individual.id for individual in new_archive_individuals]
    else
        new_archive_ids = Int[]
    end
    new_species = ArchiveSpecies(species.id, new_population, new_archive, new_archive_ids)
    #new_species_ids = [individual.id for individual in new_species.population]
    #println("new_species_ids = ", new_species_ids)
    n_population_after = length(new_species.population)
    if n_population_after != n_population_before
        error("Population size changed from $n_population_before to $n_population_after")
    end


    return new_species
end

using ...Abstract.States: find_by_id

function create_species(
    species_creator::ArchiveSpeciesCreator, species::ArchiveSpecies, state::State
)
    evaluation = find_by_id(state.evaluations, species.id,)
    species = create_species(species_creator, species, evaluation, state)
    return species
end


end