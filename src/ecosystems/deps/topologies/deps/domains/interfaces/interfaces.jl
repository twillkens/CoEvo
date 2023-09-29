module Interfaces

export create_domain, next!, refresh!, assign_entities!, get_outcomes

using ..Abstract: Domain, DomainCreator, Phenotype

function create_domain(::String, domain_creator::DomainCreator)
    throw(ErrorException(
        "`create_domain` not implemented for $domain "
        )
    )
end

function next!(domain::Domain)
    throw(ErrorException(
        "`next!` not implemented for domain $domain"
        )
    )
end

function refresh!(domain::Domain)
    throw(ErrorException(
        "`refresh!` not implemented for domain $domain"
        )
    )
end

function assign_entities!(domain::Domain, phenotypes::Vector{<:Phenotype})
    throw(ErrorException(
        "`assign_entities!` not implemented for domain $domain, phenotypes $phenotypes"
        )
    )
end

function get_outcomes(domain::Domain)
    throw(ErrorException(
        "`get_outcomes` not implemented for domain $domain"
        )
    )
end

end