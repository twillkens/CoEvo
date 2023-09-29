module Abstract

export Observation, Observer, observe!, create_observation, Metric, Domain

using ......Ecosystems.Abstract: Metric

using ...Domains.Abstract: Domain

abstract type Observation end

abstract type Observer end

function observe!(domain::Domain, observer::Observer)
    error("`observe!`` not implemented for $(typeof(domain)), $(typeof(observer))")
end

function create_observation(observer::Observer)::Observation
    error("`create_observation`` not implemented for $(typeof(observer))")
end

end