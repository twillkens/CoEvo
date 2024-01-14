module Results

export Null, Basic

using DataStructures: SortedDict

include("null/null.jl")
using .Null: Null

include("basic/basic.jl")
using .Basic: Basic

end