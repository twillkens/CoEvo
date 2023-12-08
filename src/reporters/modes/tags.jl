using ...Individuals: Individual, get_individuals

function reset_tag_dictionary!(reporter::ModesReporter)
    empty!(reporter.tag_dictionary)
end

function update_tag_dictionary!(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    individuals = vcat([get_individuals(species) for species in all_species]...)
    for (tag, individual) in enumerate(individuals)
        reporter.tag_dictionary[individual.id] = tag
    end
end

# Function to update tags for individuals
function update_tags!(reporter::ModesReporter, individuals::Vector{<:Individual})
    persistent_tags = Set{Int}()
    for individual in individuals
        parent_id = first(individual.parent_ids)
        if haskey(reporter.tag_dictionary, parent_id)
            tag = reporter.tag_dictionary[parent_id]
            push!(persistent_tags, tag)
            reporter.tag_dictionary[individual.id] = tag
        end
    end
    return persistent_tags
end

# Function to update persistent IDs
function update_persistent_ids!(reporter::ModesReporter, persistent_tags::Set{Int})
    empty!(reporter.persistent_ids)
    all_individuals = get_individuals(reporter.all_species)
    for individual in all_individuals
        tag = reporter.tag_dictionary[individual.id]
        if tag in persistent_tags
            push!(reporter.persistent_ids, individual.id)
        end
    end
end

# Main function calling the modularized components
function update_persistent_ids!(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    individuals = get_individuals(all_species)
    persistent_tags = update_tags!(reporter, individuals)
    update_persistent_ids!(reporter, persistent_tags)
end