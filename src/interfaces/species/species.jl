export get_individuals, get_species, get_all_ids, find_species_by_id, get_species_with_ids
export create_phenotype_dict, get_individuals_to_evaluate, get_individuals_to_perform
export get_population, get_elites, update_species!

using ..Abstract

function get_individuals_to_evaluate(species::AbstractSpecies)
    throw(ErrorException("get_individuals_to_evaluate not implemented for species of type $(typeof(species))"))
end

function get_individuals_to_perform(species::AbstractSpecies)
    throw(ErrorException("get_individuals_to_perform not implemented for species of type $(typeof(species))"))
end

function get_population_genotypes(species::AbstractSpecies)
    throw(ErrorException("get_population_genotypes not implemented for species of type $(typeof(species))"))
end

function convert_to_dictionary(species::AbstractSpecies)
    error("convert_to_dictionary not implemented for species of type $(typeof(species))")
end

function convert_from_dictionary(
    species_creator::SpeciesCreator, 
    individual_creator::IndividualCreator,
    genotype_creator::GenotypeCreator,
    phenotype_creator::PhenotypeCreator,
    dict::Dict
)
    species_creator_type = typeof(species_creator)
    individual_creator_type = typeof(individual_creator)
    genotype_creator_type = typeof(genotype_creator)
    phenotype_creator_type = typeof(phenotype_creator)
    error("convert_from_dictionary not implemented for $species_creator_type, " *
        "$individual_creator_type, $genotype_creator_type, $phenotype_creator_type, and $dict"
    )
end

function get_minimized_population_genotypes(species::AbstractSpecies)
    genotypes = get_population_genotypes(species)
    genotypes = [minimize(genotype) for genotype in genotypes]
    return genotypes
end

# Function to extract all individuals from a list of species
function get_individuals(all_species::Vector{<:AbstractSpecies})
    return vcat([get_individuals(species) for species in all_species]...)
end

function get_individuals(species::AbstractSpecies, cohorts::Vector{String})
    individuals = vcat([getfield(species, Symbol(cohort)) for cohort in cohorts]...)
    return individuals
end

get_population(species::AbstractSpecies) = species.population

get_elites(species::AbstractSpecies) = species.elites


function get_species(all_species::Vector{<:AbstractSpecies}, species_id::String)
    species_vector = filter(species -> species.id == species_id, all_species)
    if length(species_vector) == 0
        throw(ErrorException("No species with id $species_id"))
    elseif length(species_vector) > 1
        throw(ErrorException("Multiple species with id $species_id"))
    end
    species = first(species_vector)
    return species
end

function get_all_ids(all_species::Vector{<:AbstractSpecies})
    all_individuals = vcat([get_individuals(species) for species in all_species]...)
    all_ids = Set(individual.id for individual in all_individuals)
    return all_ids
end

function find_species_by_id(species_id::String, species_list::Vector{<:AbstractSpecies})
    index = findfirst(s -> s.id == species_id, species_list)
    if index === nothing
        throw(ErrorException("Species with id $species_id not found."))
    end
    return species_list[index]
end

function get_species_with_ids(
    all_species::Vector{<:AbstractSpecies}, species_ids::Vector{String}, 
)
    species = [find_species_by_id(species_id, all_species) for species_id in species_ids]
    return species
end

function create_phenotype_dict(
    all_species::Vector{<:AbstractSpecies},
    phenotype_creators::Vector{<:PhenotypeCreator},
    ids::Set{Int},
)
    phenotype_dict = Dict(
        individual.id => create_phenotype(phenotype_creator, individual)
        for (species, phenotype_creator) in zip(all_species, phenotype_creators)
        for individual in get_individuals_to_perform(species)
        if individual.id in ids
    )
    return phenotype_dict

end

function update_species!(species::AbstractSpecies)
    error("update_species! not implemented for species of type $(typeof(species))")
end