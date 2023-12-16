using ...Individuals: Individual, get_individuals

using ...Species.AdaptiveArchive: AdaptiveArchiveSpecies
using ...Species.Basic: BasicSpecies


function reset_tag_dictionary!(reporter::ModesReporter)
    empty!(reporter.tag_dictionary)
end

function update_tag_dictionary!(reporter::ModesReporter, all_species::Vector{<:BasicSpecies})
    individuals = vcat([get_individuals(species) for species in all_species]...)
    println("tag dictionary before update: ", reporter.tag_dictionary)
    for (tag, individual) in enumerate(individuals)
        reporter.tag_dictionary[individual.id] = tag
    end
    println("tag dictionary after update: ", reporter.tag_dictionary)
end

function update_tag_dictionary!(
    reporter::ModesReporter, all_species::Vector{<:AdaptiveArchiveSpecies}
)
    all_basic_species = [species.basic_species for species in all_species]
    update_tag_dictionary!(reporter, all_basic_species)
end

# Function to update tags for individuals
function update_tags!(reporter::ModesReporter, individuals::Vector{<:Individual})
    persistent_tags = Set{Int}()
    println("tag_dictionary before update: ", reporter.tag_dictionary)
    for individual in individuals
        parent_id = first(individual.parent_ids)
        if haskey(reporter.tag_dictionary, parent_id)
            tag = reporter.tag_dictionary[parent_id]
            push!(persistent_tags, tag)
            reporter.tag_dictionary[individual.id] = tag
        end
    end
    println("tag_dictionary after update: ", reporter.tag_dictionary)
    return persistent_tags
end

# Function to update persistent IDs
function update_persistent_ids!(reporter::ModesReporter, persistent_tags::Set{Int})
    println("persistent_tags: $persistent_tags")
    println("persistent_ids before: ", reporter.persistent_ids)
    empty!(reporter.persistent_ids)
    all_individuals = get_individuals(reporter.all_species)
    for individual in all_individuals
        tag = reporter.tag_dictionary[individual.id]
        if tag in persistent_tags
            push!(reporter.persistent_ids, individual.id)
        end
    end
    println("persistent_ids after: ", reporter.persistent_ids)
end

# Main function calling the modularized components
function update_persistent_ids!(reporter::ModesReporter, all_species::Vector{<:BasicSpecies})
    individuals = get_individuals(all_species)
    persistent_tags = update_tags!(reporter, individuals)
    update_persistent_ids!(reporter, persistent_tags)
end

function update_persistent_ids!(
    reporter::ModesReporter, all_species::Vector{<:AdaptiveArchiveSpecies}
)
    all_basic_species = [species.basic_species for species in all_species]
    update_persistent_ids!(reporter, all_basic_species)
end

function set_persistent_ids!(reporter::ModesReporter, all_species::Vector{<:BasicSpecies})
    empty!(reporter.persistent_ids)
    for id in get_all_ids(all_species)
        push!(reporter.persistent_ids, id)
    end
end

function initialize_checkpoint!(reporter::ModesReporter, all_species::Vector{<:BasicSpecies})
    update_species_list!(reporter, all_species)
    reset_tag_dictionary!(reporter)
    update_tag_dictionary!(reporter, all_species)
    set_persistent_ids!(reporter, all_species)
end
