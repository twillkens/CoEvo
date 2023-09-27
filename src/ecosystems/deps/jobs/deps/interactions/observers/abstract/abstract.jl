module Abstract

export observe!, make_observation

using ....CoEvo.Abstract: Domain, Observer

function observe!(domain::Domain, observer::Observer)
    error("`observe!`` not implemented for $(typeof(domain)), $(typeof(observer))")
end

observe!(domain::Domain, observers::Vector{<:Observer}) = [
   observe!(domain, observer) for observer in observers
]

function make_observation(observer::Observer)
    error("`make_observation`` not implemented for $(typeof(observer))")
end


end