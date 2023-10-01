module Methods

export observe!

using ..Abstract: Observer, Environment

observe!(env::Environment, observers::Vector{<:Observer}) = [
   observe!(env, observer) for observer in observers
]

end