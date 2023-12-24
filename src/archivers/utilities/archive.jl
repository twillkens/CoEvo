export add_measurements_to_hdf5

using HDF5: File

function add_measurements_to_hdf5(file::File, path::String, dict::Dict{T, U}) where {T, U}
    for (key, value) in dict
        new_path = joinpath(path, string(key))
        #println(key, value)
        if isa(value, Dict)
            add_measurements_to_hdf5(file, new_path, value)
        elseif isa(value, Real)
            file[new_path] = float(value)
        else
            error("Unsupported type in measurements")
        end
    end
end
