"""
    Counters

The `Counters` module provides utilities and structures for counting and tracking information
such as individual and gene IDs.
"""
module Counters

export Basic

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

end