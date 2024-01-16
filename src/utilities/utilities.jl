module Utilities

export find_by_id, get_git_commit_hash, current_date_time, find_recent_valid_checkpoint_path
export save_dict_to_hdf5!, load_dict_from_hdf5

using Dates
using HDF5: File, h5open, Group, close, read

function find_by_id(collection::Vector{T}, id::I) where {T, I}
    filtered = filter(item -> item.id == id, collection)
    if length(filtered) == 0
        error("Could not find item with id $id")
    elseif length(filtered) > 1
        error("Multiple items with id $id found")
    else
        return first(filtered)
    end
end

function find_by_id(collection::Vector{T}, ids::Vector{I}) where {T, I}
    return [find_by_id(collection, id) for id in ids]
end

function get_git_commit_hash()
    output = IOBuffer()
    error_output = IOBuffer()
    
    cmd = pipeline(`git rev-parse HEAD`, stdout=output, stderr=error_output)
    run(cmd)
    
    # Check for errors
    if !isempty(String(take!(error_output)))
        return "<null>"
    end

    # Return the commit hash
    git_commit_hash = strip(String(take!(output)))  # Remove any trailing newline
    return git_commit_hash
end

function current_date_time()
    return Dates.format(now(), "Y-m-d H:M:S")
end

function find_recent_valid_checkpoint_path(archive_directory::String)
    generations_directory = joinpath(archive_directory, "generations")
    checkpoint_files = filter(x -> occursin(r"\.h5$", x), readdir(generations_directory))
    sort!(checkpoint_files, by = x -> parse(Int, match(r"(\d+)\.h5$", x).captures[1]), rev = true)
    
    for chk_file in checkpoint_files
        file_path = joinpath(generations_directory, chk_file)  # Corrected the path
        file = nothing  # Initialize `file` to nothing
        try
            file = h5open(file_path, "r")
            if "valid" in keys(file) && read(file["valid"])
                println("Valid checkpoint found: $file_path")
                return file_path  # Return the path of the valid checkpoint
            else
                # The checkpoint is invalid as writing must have been interrupted before
                # the "valid" flag was written. Delete the checkpoint and continue.
                println("Invalid checkpoint, deleting: $file_path")
                rm(file_path; force=true)
            end
        catch e
            println("Error reading checkpoint $file_path: $e")
            # Delete the corrupted file
            if isfile(file_path)
                rm(file_path; force=true)
            end
        finally
            # Safely attempt to close the file if it was opened
            if file !== nothing
                close(file)
            end
        end
    end
    return nothing  # Return nothing if no valid checkpoints are found
end

function save_dict_to_hdf5!(file::File, path::String, dict::Dict)
    for (key, value) in dict
        new_path = joinpath(path, string(key))
        #println(key, value)
        if isa(value, Dict)
            save_dict_to_hdf5!(file, new_path, value)
        elseif isa(value, Real) || 
            isa(value, Vector{<:Real}) || 
            isa(value, Vector{String}) || 
            isa(value, String
        )
            file[new_path] = value
        else
            println("path = $path")
            println("new_path = $new_path")
            println("value = $value")
            error("Unsupported type in measurements")
        end
    end
end

function save_dict_to_hdf5!(file::String, path::String, dict::Dict, mode::String = "r+")
    file = h5open(file, mode)
    save_dict_to_hdf5!(file, path, dict)
    close(file)
end

function load_dict_from_hdf5(file::File, current_path::String = "/")
    dict = Dict()
    for name in keys(file[current_path])
        new_path = joinpath(current_path, name)
        if typeof(file[new_path]) == Group
            # Recursively convert groups to dictionaries
            dict[name] = load_dict_from_hdf5(file, new_path)
        else
            value = read(file[new_path])
            dict[name] = value
        end
    end
    return dict
end

function load_dict_from_hdf5(file_path::String, current_path::String = "/")
    file = h5open(file_path, "r")
    dict = load_dict_from_hdf5(file, current_path)
    close(file)
    return dict
end

end