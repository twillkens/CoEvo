module Abstract

export observe!, make_observation

using ....CoEvo.Abstract: Domain, Observer

function observe!(::Domain, ::Observer)
    error("`observe!`` not implemented for $(typeof(domain))")
end

observe!(domain::Domain, observers::Vector{<:Observer}) = [
   observe!(domain, observer) for observer in observers
]

function make_observation(::Observer)
    error("`make_observation`` not implemented for $(typeof(observer))")
end


end