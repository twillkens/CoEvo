module Utilities

export find_by_id

function find_by_id(collection::Vector{T}, id::I) where {T, I}
    filtered = filter(item -> item.id == id, collection)
    if length(filtered) == 0
        throw(ErrorException("Could not find item with id $id"))
    elseif length(filtered) > 1
        throw(ErrorException("Multiple items with id $id found"))
    else
        return first(filtered)
    end
end

end