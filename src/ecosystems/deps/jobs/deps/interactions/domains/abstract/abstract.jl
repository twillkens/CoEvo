
module Abstract

export Domain, next!, refresh!

abstract type Domain end

function next!(::D) where {D <: Domain}
    throw(ErrorException(
        "`next!` not implemented for domain $D"
        )
    )
end

function refresh!(::D) where {D <: Domain}
    throw(ErrorException(
        "`refresh!` not implemented for domain $D"
        )
    )
end

end