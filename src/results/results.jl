module Results

export Null, Basic

using DataStructures: SortedDict

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("null/null.jl")
using .Null: Null

include("basic/basic.jl")
using .Basic: Basic

end