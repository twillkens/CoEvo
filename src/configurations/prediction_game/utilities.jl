export load_type

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