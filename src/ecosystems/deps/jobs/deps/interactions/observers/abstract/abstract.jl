module Abstract

export observe!, make_observation

using ....Abstract: Domain
using ....CoEvo.Abstract: Domain, Observer


function observe!(domain::Domain, observer::Observer)
    error("`observe!`` not implemented for $(typeof(domain)), $(typeof(observer))")
end

function make_observation(observer::Observer)
    error("`make_observation`` not implemented for $(typeof(observer))")
end


end