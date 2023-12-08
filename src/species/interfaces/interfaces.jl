export get_individuals, get_species, get_all_ids

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
