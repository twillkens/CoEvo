using ..Interactions.Domains.Abstract: Domain, DomainCreator
using .Abstract: Observer

observe!(env::Environment, observers::Vector{<:Observer}) = [
   observe!(env, observer) for observer in observers
]
