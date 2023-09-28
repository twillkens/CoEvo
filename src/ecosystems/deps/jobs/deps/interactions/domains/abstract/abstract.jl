module Abstract

export Domain, DomainCreator, create_domain, next!, refresh!

abstract type Domain end

abstract type DomainCreator end

function create_domain(::String, ::DomainCreator)
    throw(ErrorException(
        "`create_domain` not implemented for domain $S"
        )
    )
end

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