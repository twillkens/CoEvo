module Utilities

export get_or_make_group!

using JLD2: Group, File

"""
    get_or_make_group!(group::Union{File, Group}, path::String)

Accesses or creates a group within a JLD2 file based on the given path. If the path doesn't exist, 
this function will create the necessary nested groups.

# Arguments:
- `group::Union{File, Group}`: The parent group or file to start from.
- `path::String`: The path to the desired group, with parts separated by '/'.

# Returns:
- The group corresponding to the final part of the path.
"""
function get_or_make_group!(group::Union{File, Group}, path::String)
    # Split the path into parts
    parts = split(path, '/')
    
    # Iteratively create or access groups based on path parts
    for part in parts
        group = part ∉ keys(group) ? Group(group, part) : group[part]
    end
    
    return group
end

"""
    get_or_make_group!(group::Union{File, Group}, key::Union{Symbol, UInt32, Int})

A convenience overload that converts the key to a string and then accesses or creates the group.

# Arguments:
- `group::Union{File, Group}`: The parent group or file to start from.
- `key::Union{Symbol, UInt32, Int}`: The key representing the desired group.

# Returns:
- The group corresponding to the key.
"""
function get_or_make_group!(group::Union{File, Group}, key::Union{Symbol, UInt32, Int})
    get_or_make_group!(group, string(key))
end

end