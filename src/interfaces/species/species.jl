export get_individuals, get_individuals_to_evaluate, get_individuals_to_perform
export update_species!, convert_to_dict, create_from_dict

using ..Abstract

function get_individuals(species::AbstractSpecies)
    error("get_individuals not implemented for species of type $(typeof(species))")
end

function get_individuals_to_evaluate(species::AbstractSpecies)
    error("get_individuals_to_evaluate not implemented for species of type $(typeof(species))")
end

function get_individuals_to_perform(species::AbstractSpecies)
    error("get_individuals_to_perform not implemented for species of type $(typeof(species))")
end

function convert_to_dict(species::AbstractSpecies)
    error("convert_to_dict not implemented for species of type $(typeof(species))")
end

function update_species!(species::AbstractSpecies)
    error("update_species! not implemented for species of type $(typeof(species))")
end