using JLD2
using ProgressBars

struct FilterTag
    gen::Int
    spid::String
    iid::String
    prevtag::Int
    currtag::Int
end

function print_tags(tags::Vector{FilterTag}, generation::Int = 0)
    println("Generation $generation:")
    for tag in tags
        println("\tFilterTag(gen: $(tag.gen), species: $(tag.spid), id: $(tag.iid), prevtag: $(tag.prevtag), currtag: $(tag.currtag))")
    end
    println()  # Add an empty line for better separation between generations
end

function print_tags(tags::Vector{Vector{FilterTag}}, start_gen::Int, end_gen::Int)
    for (gen_index, generation) in enumerate(tags)
        if gen_index >= start_gen && gen_index <= end_gen
            print_tags(generation, gen_index)
        end
    end
end

function init_filter_tags(
    file::JLD2.JLDFile,
    species::String
)
    tagging_dict = Dict{String, Int}()
    initial_filter_tags = Vector{FilterTag}()  # Vector to hold FilterTag objects
    n_parents = length(file["individuals/1/$species/population_ids"])
    children_group = file["individuals/1/$species/children"]
    n_children = length(keys(children_group))
    n_population = n_parents + n_children

    for tag in 1:n_population
        tagging_dict[string(tag)] = tag
        filter_tag = FilterTag(1, species, string(tag), 0, tag)
        push!(initial_filter_tags, filter_tag)
    end
    filter_tags = [initial_filter_tags]
    println("Initial tagging dictionary: ", tagging_dict)
    println("Initial filter tags: ", filter_tags)

    tagging_dict, filter_tags   # Enclosing initial_filter_tags in a list
end

function refresh_tags(
    file::JLD2.JLDFile,
    generation::Int,
    species::String,
    previous_filter_tags::Vector{Vector{FilterTag}},
    tagging_dictionary::Dict{String, Int}
)
    children_group = file["individuals/$generation/$species/children"]
    new_tagging_dict = Dict{String, Int}()
    filter_tags = Vector{FilterTag}()
    population_ids = string.(file["individuals/$generation/$species/population_ids"])
    children_ids = keys(children_group)
    all_population_ids = [population_ids; children_ids]

    for (index, individual_id) in enumerate(all_population_ids)
        new_tagging_dict[individual_id] = index
        if individual_id ∈ population_ids
            parent_id = individual_id
        else
            parent_id = string(first(children_group[individual_id]["parent_ids"]))
        end
        previous_tag = tagging_dictionary[parent_id]
        filter_tag = FilterTag(generation, species, individual_id, previous_tag, index)
        push!(filter_tags, filter_tag)
    end
    println("-----------")
    println("Previous")
    print_tags(previous_filter_tags[end], generation - 1)
    println("Current")
    print_tags(filter_tags, generation)

    next_tags = Set([tag.prevtag for tag in filter_tags])
    filter!(tag -> tag.currtag in next_tags, previous_filter_tags[end])
    println("Filtered")
    print_tags(previous_filter_tags[end], generation - 1) 
    push!(previous_filter_tags, filter_tags)

    new_tagging_dict
end


function pass_tags(
    file::JLD2.JLDFile,
    generation::Int,
    species::String,
    tagging_dictionary::Dict{String, Int}
)
    children_group = file["individuals/$generation/$species/children"]
    population_ids = string.(file["individuals/$generation/$species/population_ids"])
    children_ids = keys(children_group)
    all_population_ids = [population_ids; children_ids]
    tag_mappings = map(all_population_ids) do individual_id
        if individual_id ∈ population_ids
            parent_id = individual_id
        else
            parent_id = string(first(children_group[individual_id]["parent_ids"]))
        end
        try 
            individual_id => tagging_dictionary[string(parent_id)]
        catch
            println(tagging_dictionary)
            throw(ErrorException("Error: $individual_id, $parent_id"))
        end
    end

    Dict(tag_mappings)
end

function process_tags_for_species(
    file::JLD2.JLDFile,
    species::String,
    tagging_interval::Int,
    max_generation::Int = typemax(Int)
)
    tagging_dict, previous_filter_tags = init_filter_tags(file, species)
    for generation in ProgressBar(2:length(keys(file["individuals"])))
        if generation > max_generation
            break
        end

        if generation % tagging_interval == 0
            # Update the tagging dictionary and previous_filter_tags separately
            new_tagging_dict = refresh_tags(
                file, generation, species, previous_filter_tags, tagging_dict
            )
            tagging_dict = new_tagging_dict
        else
            tagging_dict = pass_tags(file, generation, species, tagging_dict)
        end
    end

    pop!(previous_filter_tags)
    previous_filter_tags
end

function process_all_tags(
    file_path::String,
    tagging_interval::Int,
    max_generation::Int = typemax(Int)
)
    file = jldopen(file_path, "r")
    species_ids = keys(file["individuals/1"])

    all_tags = [
        process_tags_for_species(file, species_id, tagging_interval, max_generation)
        for species_id in species_ids
    ]

    close(file)
    all_tags
end

