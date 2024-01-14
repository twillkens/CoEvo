import ....Interfaces: archive!
using HDF5: File, Group, create_group

function archive!(file::File, path::String, dict::Dict{T, U}) where {T, U}
    for (key, value) in dict
        new_path = joinpath(path, string(key))
        #println(key, value)
        if isa(value, Dict)
            archive!(file, new_path, value)
        elseif isa(value, Real) || isa(value, Vector{<:Real}) || isa(value, Vector{String})
            file[new_path] = value
        else
            error("Unsupported type in measurements")
        end
    end
end
