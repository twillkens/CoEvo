
observe!(domain::Domain, observers::Vector{<:Observer}) = [
   observe!(domain, observer) for observer in observers
]
