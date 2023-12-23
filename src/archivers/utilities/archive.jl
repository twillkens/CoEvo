export add_measurements_to_hdf5

using HDF5: File

function add_measurements_to_hdf5(file::File, path::String, dict::Dict{Any, Any})
    for (key, value) in dict
        new_path = joinpath(path, string(key))
        if isa(value, Dict)
            add_measurements_to_hdf5(new_path, value, file)
        elseif isa(value, Float64)
            file[new_path] = value
        else
            error("Unsupported type in measurements")
        end
    end
end
