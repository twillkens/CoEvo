module Utilities

export find_by_id

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

end