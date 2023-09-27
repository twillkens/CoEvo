
abstract type Setting end

function create_domain(::String, ::S) where {S <: Setting}
    throw(ErrorException(
        "`create_domain` not implemented for setting $S"
        )
    )
end