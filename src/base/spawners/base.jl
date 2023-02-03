abstract type Gene end
abstract type Replacer end
abstract type Recombiner end
abstract type Mutator end


include("species.jl")
include("replacers.jl")
include("mutators.jl")
include("recombiners.jl")
include("orders.jl")
include("selector.jl")
include("variators.jl")
include("vector.jl")
include("coev.jl")
include("vector.jl")