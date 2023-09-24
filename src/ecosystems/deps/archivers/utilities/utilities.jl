module Utilities

export get_or_make_group!

using JLD2: Group, File

function get_or_make_group!(group::Union{File, Group}, path::String)
    # Split the path into parts
    parts = split(path, '/')
    
    # Iteratively create or access groups based on path parts
    for part in parts
        group = part ∉ keys(group) ? Group(group, part) : group[part]
    end
    
    return group
end

function get_or_make_group!(group::Union{File, Group}, key::Union{Symbol, UInt32, Int})
    get_or_make_group!(group, string(key))
end

end