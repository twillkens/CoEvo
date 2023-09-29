using ..Interactions.Domains.Abstract: Domain, DomainCreator
using .Abstract: Observer

observe!(domain::Domain, observers::Vector{<:Observer}) = [
   observe!(domain, observer) for observer in observers
]
