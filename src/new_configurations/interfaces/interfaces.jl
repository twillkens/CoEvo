export load_type, archive!, get_id

import ..Archivers: archive!

using HDF5: File, Group

get_id(config::Configuration) = config.id

function load_type(type::Type, file::File, base_path::String)
    # Use reflection to get the fields of the substrate type
    fields = fieldnames(type)

    # Create a dictionary to hold the field values
    field_values = Dict{Symbol, Any}()

    # Populate the field values from the file
    for field in fields
        field_key = "$base_path/$field"
        if haskey(file, field_key)
            field_values[field] = read(file[field_key])
        else
            error("Required field $field_key not found in file for $type in $base_path")
        end
    end

    # Dynamically create an instance of the substrate type
    loaded_type = type(; (Symbol(field) => value for (field, value) in field_values)...)
    return loaded_type
end

function load_from_archive(file::File, config_type::Type{T}, base_path::String) where T <: Configuration
    # Create an array to hold field values
    field_values = []

    for field in fieldnames(config_type)
        field_path = joinpath(base_path, string(field))
        value = read(file[field_path])
        if typeof(value) isa Group
            # If the field is a group, it's a nested configuration
            field_type = fieldtype(config_type, field)
            value = load_from_archive(file, field_type, field_path)
            push!(field_values, value)
        else
            # Otherwise, it's a regular field
            push!(field_values, value)
        end
    end

    # Create an instance of the configuration type
    instance = config_type(field_values...)
    return instance
end

function archive!(file::File, configs::Vector{<:Configuration}, base_path::String)
    for config in configs
        archive!(file, config, joinpath(base_path, get_id(config)))
    end
end


# Base method for archiving any Configuration
function archive!(file::File, config::Configuration, base_path::String)
    for field in fieldnames(typeof(config))
        field_path = joinpath(base_path, string(field))
        value = getfield(config, field)
        #println("Archiving field $field_path with value $(typeof(value))")
        if typeof(value) <: Configuration || isa(value, Vector) && eltype(value) <: Configuration
            archive!(file, value, field_path)
        else
            file[field_path] = value
        end
    end
end