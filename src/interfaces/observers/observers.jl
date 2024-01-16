export observe!, create_observation 

using ..Abstract

function observe!(observer::Observer, environment::Environment)
    observer = typeof(observer)
    environment = typeof(environment)
    error("`observe!` not implemented for $(typeof(observer)) and $(typeof(environment))")
end

function create_observation(observer::Observer)
    observer = typeof(observer)
    error("create_observation not implemented for $observer")
end