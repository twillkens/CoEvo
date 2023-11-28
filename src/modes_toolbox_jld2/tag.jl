using JLD2
using ProgressBars
using CoEvo

struct FilterTag
    gen::Int
    species_id::String
    id::Int
    previous_tag::Int
    current_tag::Int
end

function print_tags(tags::Vector{FilterTag}, generation::Int = 0)
    println("Generation $generation:")
    for tag in tags
        println("\tFilterTag(gen: $(tag.gen),  id: $(tag.id), prevtag: $(tag.previous_tag), currtag: $(tag.current_tag))")
    end
    println() 
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
    species::String,
)
    tagging_dict = Dict{Int, Int}()
    initial_filter_tags = Vector{FilterTag}()  # Vector to hold FilterTag objects
    n_parents = length(file["individuals/1/$species/population_ids"])
    population_ids = [parse(Int, key) for key in keys(file["individuals/1/$species/children"])]
    children_ids = [id + n_parents for id in population_ids]
    ids = [population_ids; children_ids]

    for id in ids
        tagging_dict[id] = id
        filter_tag = FilterTag(1, species, id, 0, id)
        push!(initial_filter_tags, filter_tag)
    end
    filter_tags = [initial_filter_tags]
    tagging_dict, filter_tags
end

function get_population_ids(
    file::JLD2.JLDFile,
    generation::Int,
    species::String
)
    children_group = file["individuals/$generation/$species/children"]
    children_ids = [parse(Int, key) for key in keys(children_group)]
    population_ids = file["individuals/$generation/$species/population_ids"]
    all_population_ids = [population_ids; children_ids]
    return all_population_ids
end

function get_parent_id(
    file::JLD2.JLDFile,
    generation::Int,
    species::String,
    individual_id::Int
)
    population_ids = file["individuals/$generation/$species/population_ids"]
    if individual_id ∈ population_ids
        parent_id = individual_id
    else
        parent_ids = file["individuals/$generation/$species/children/$individual_id/parent_ids"]
        parent_id = first(parent_ids)
    end
    return parent_id
end
    
function refresh_tags(
    file::JLD2.JLDFile,
    generation::Int,
    species::String,
    previous_filter_tags::Vector{Vector{FilterTag}},
    tagging_dictionary::Dict{Int, Int}
)
    new_tagging_dict = Dict{Int, Int}()
    filter_tags = Vector{FilterTag}()
    all_population_ids = get_population_ids(file, generation, species)

    for (new_tag, individual_id) in enumerate(all_population_ids)
        new_tagging_dict[individual_id] = new_tag
        parent_id = get_parent_id(file, generation, species, individual_id)
        previous_tag = tagging_dictionary[parent_id]
        filter_tag = FilterTag(generation, species, individual_id, previous_tag, new_tag)
        push!(filter_tags, filter_tag)
    end
    next_tags = Set([tag.previous_tag for tag in filter_tags])
    filter!(tag -> tag.current_tag in next_tags, previous_filter_tags[end])
    push!(previous_filter_tags, filter_tags)

    return new_tagging_dict
end

function pass_tags(
    file::JLD2.JLDFile,
    generation::Int,
    species::String,
    tagging_dictionary::Dict{Int, Int}
)
    all_population_ids = get_population_ids(file, generation, species)
    tag_mappings = map(all_population_ids) do individual_id
        parent_id = get_parent_id(file, generation, species, individual_id)
        try 
            individual_id => tagging_dictionary[parent_id]
        catch
            println(tagging_dictionary)
            throw(ErrorException("Error: $individual_id, $parent_id"))
        end
    end

    new_tagging_dict = Dict(tag_mappings)
    return new_tagging_dict
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
        tagging_dict = generation % tagging_interval == 0 ?
            refresh_tags(file, generation, species, previous_filter_tags, tagging_dict) :
            pass_tags(file, generation, species, tagging_dict)
    end
    pop!(previous_filter_tags)
    vcat(previous_filter_tags...)
end

struct GenerationTagBundle
    generation::Int
    all_species_tags::Dict{String, Vector{FilterTag}}
end

function get_generation_tag_bundles(
    file::JLD2.JLDFile = jldopen("/media/tcw/Seagate/two_comp_1/1.jld2", "r"),
    tagging_interval::Int = 50,
    max_generation::Int = typemax(Int)
)
    species_ids = keys(file["individuals/1"])

    all_tags = vcat([
        process_tags_for_species(file, species_id, tagging_interval, max_generation) 
        for species_id in species_ids]...
    )
    generations = sort(collect(Set(tag.gen for tag in all_tags)))
    tags_by_generation = [
        filter(tag -> tag.gen == generation, all_tags)
        for generation in generations
    ]
    tag_bundles = GenerationTagBundle[]
    for (generation, generation_tags) in zip(generations, tags_by_generation)
        all_species_tags = Dict{String, Vector{FilterTag}}()
        for species_id in species_ids
            species_tags = filter(tag -> tag.species_id == species_id, generation_tags)
            all_species_tags[species_id] = species_tags
        end
        tag_bundle = GenerationTagBundle(generation, all_species_tags)
        push!(tag_bundles, tag_bundle)
    end
    return tag_bundles
end
