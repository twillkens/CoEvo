export get_individuals, get_species, get_all_ids, find_species_by_id, get_species_with_ids
export create_phenotype_dict, get_individuals_to_evaluate, get_individuals_to_perform

using ..Phenotypes: PhenotypeCreator, create_phenotype

function get_individuals_to_evaluate(species::AbstractSpecies)
    throw(ErrorException("get_individuals_to_evaluate not implemented for species of type $(typeof(species))"))
end

function get_individuals_to_perform(species::AbstractSpecies)
    throw(ErrorException("get_individuals_to_perform not implemented for species of type $(typeof(species))"))
end

# Function to extract all individuals from a list of species
function get_individuals(all_species::Vector{<:AbstractSpecies})
    return vcat([get_individuals(species) for species in all_species]...)
end

function get_individuals(species::AbstractSpecies, cohorts::Vector{String})
    individuals = vcat([getfield(species, Symbol(cohort)) for cohort in cohorts]...)
    return individuals
end

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

